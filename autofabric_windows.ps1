# ::############################################################################
# :: autofabric_windows.ps1 
# ::
# :: This will install ollama, deepseek-r1, fabric, golang, update PATH vars and
# :: for the most part simplify deploying a local LLM with fabric.
# ::
# :: PURPOSE:
# ::   1) --interactive -i to set paths manually
# ::   2) Install dependencies (git, curl, go, ollama) as needed.
# ::   3) Clone the Fabric repository into a folder named "fabric".
# ::   4) Run "install_fabric.bat" (in the cloned repository) as Admin
# ::      to handle the actual Fabric installation steps.
# ::   5) Configure Ollama model, test it, set up Fabric patterns, and test piping.
# ::
# :: IMPORTANT WINDOWS NOTES:
# ::   - Unable to execute script from powershell? Run this in the shell
# ::     Set-ExecutionPolicy Bypass -Scope Process -Force
# ::   - The "install_fabric.bat" script must be run as Administrator. We will
# ::     check for administrative privileges in PowerShell before proceeding.
# ::   - We add "C:\Users\<username>\go\bin" (i.e., $env:USERPROFILE\go\bin)
# ::     to PATH for the current session. No new shells are opened.
# ::
# :: USAGE:
# ::   1) Open an elevated PowerShell (right-click -> Run as administrator) 
# ::      on Windows. Due to compatibility issues, see autofabric_linux.ps1 for
# ::      mac/linux.
# ::   2) Run this script.
# ::############################################################################


param(
    [switch]$Interactive
)

#region Log & Stop
# Log errors verbosely to errors.log with a timestamp.
function Log-Err {
    param(
        [Parameter(Mandatory=$true)]
        [string]$Msg
    )
    $time = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $line = "$time - $Msg"
    Add-Content -Path "errors.log" -Value $line
}

# Halt script execution (without closing the shell).
function Stop-Script {
    param(
        [string]$Msg = "Critical error encountered. Script halted."
    )
    Log-Err $Msg
    Write-Host $Msg -ForegroundColor Red
    Read-Host "Press Enter to exit"
    return
}
#endregion

#region Constants
# Define apps to check. (git is required for fabric)
$APP_DEPS = @("git", "go", "fabric", "ollama")

# Installer URLs (repo links end with .git or contain github.com).
$APP_INSTALLERS = @{
    "git"    = "https://github.com/git-for-windows/git/releases/download/v2.41.0.windows.1/Git-2.41.0-64-bit.exe"
    "go"     = "https://golang.org/dl/go1.21.0.windows-amd64.msi"
    "fabric" = "https://github.com/fabric/fabric.git"
    "ollama" = "https://ollama.com/download/OllamaSetup.exe"
}

# Default install locations.
$GO_BASE     = "C:\Go"                   # Where Go is installed.
$FABRIC_BASE = "$env:USERPROFILE\fabric" # Where the Fabric repo is cloned.
$TEMP_DIR    = "C:\Temp"                 # Where EXE/MSI installers are downloaded.
$GO_BIN      = "$env:USERPROFILE\go\bin" # Where Go binaries reside.
$LLM         = "deepseek-r1"            # Example LLM name.
#endregion

#region Interactive Setup
if ($Interactive) {
    $inp = Read-Host "Enter GO base path (default: $GO_BASE) - (location where Go is installed)"
    if (-not [string]::IsNullOrWhiteSpace($inp)) { $GO_BASE = $inp }

    $inp = Read-Host "Enter FABRIC base path (default: $FABRIC_BASE) - (location where Fabric repo is cloned)"
    if (-not [string]::IsNullOrWhiteSpace($inp)) { $FABRIC_BASE = $inp }

    $inp = Read-Host "Enter TEMP dir (default: $TEMP_DIR) - (location for downloading installers)"
    if (-not [string]::IsNullOrWhiteSpace($inp)) { $TEMP_DIR = $inp }

    $inp = Read-Host "Enter GO BIN path (default: $GO_BIN) - (location where Go binaries reside)"
    if (-not [string]::IsNullOrWhiteSpace($inp)) { $GO_BIN = $inp }
}
#endregion

#region Elevate Privileges
$prin = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
if (-not $prin.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "Not admin. Elevating..." -ForegroundColor Yellow
    try {
        Start-Process powershell.exe -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs -ErrorAction Stop
        Read-Host "Press Enter to exit the non-admin shell"
        return
    }
    catch {
        Log-Err "Elevation failed: $_"
        Stop-Script "Elevation failed. Cannot continue."
        return
    }
}
#endregion

#region Set Exec Policy
try {
    Set-ExecutionPolicy Bypass -Scope Process -Force -ErrorAction Stop
    Write-Host "Policy set to Bypass." -ForegroundColor Green
}
catch {
    Log-Err "Policy change failed: $_"
    Write-Warning "Policy change failed. Proceeding."
}
#endregion

#region Check Git (Mandatory)
try {
    $gitCmd = Get-Command git -ErrorAction Stop
    Write-Host "Git found: $($gitCmd.Source)" -ForegroundColor Green
}
catch {
    Log-Err "Git not installed."
    Stop-Script "Git is required but not installed. Please install Git and rerun the script."
    return
}
#endregion

#region Check Apps
$instList = @()  # List of apps to install.
foreach ($app in $APP_DEPS) {
    try {
        $cmd = Get-Command $app -ErrorAction Stop
        Write-Host "[$app] installed. ($($cmd.Source))" -ForegroundColor Green
    }
    catch {
        Write-Warning "[$app] not installed. Flagging for install."
        Log-Err "[$app] not found. Marked for installation."
        $instList += $app
    }
}
#endregion

#region Update PATH Function
function Upd-Path {
    param(
        [Parameter(Mandatory=$true)]
        [string]$Dir,
        [Parameter(Mandatory=$true)]
        [ValidateSet("Machine", "User")]
        [string]$Scope
    )
    if ($Scope -eq "Machine") {
        $cur = [Environment]::GetEnvironmentVariable("PATH", "Machine")
        if (-not ($cur -like "*$Dir*")) {
            $new = "$cur;$Dir"
            [Environment]::SetEnvironmentVariable("PATH", $new, "Machine")
            Write-Host "Updated Machine PATH with $Dir" -ForegroundColor Green
            Log-Err "Updated Machine PATH with $Dir"
        }
        else {
            Write-Host "$Dir already in Machine PATH" -ForegroundColor Yellow
        }
    }
    else {
        $cur = [Environment]::GetEnvironmentVariable("PATH", "User")
        if (-not ($cur -like "*$Dir*")) {
            $new = "$cur;$Dir"
            [Environment]::SetEnvironmentVariable("PATH", $new, "User")
            Write-Host "Updated User PATH with $Dir" -ForegroundColor Green
            Log-Err "Updated User PATH with $Dir"
        }
        else {
            Write-Host "$Dir already in User PATH" -ForegroundColor Yellow
        }
    }
}
#endregion

#region Install Function
function Inst-Prog {
    param(
        [Parameter(Mandatory=$true)]
        [string]$App,
        [Parameter(Mandatory=$true)]
        [string]$Url
    )
    Write-Host "Installing [$App]..." -ForegroundColor Cyan

    # If URL is a repo link (Git-based).
    if ($Url -match "\.git$" -or $Url -match "github\.com") {
        if ($App -eq "fabric") {
            $targ = $FABRIC_BASE
        }
        elseif ($App -eq "go") {
            $targ = $GO_BASE
        }
        else {
            $targ = Join-Path $env:USERPROFILE $App
        }
        Write-Host "Repo link detected for [$App]. Cloning to: $targ" -ForegroundColor Cyan
        if (Test-Path $targ) {
            $files = Get-ChildItem $targ -Force | Where-Object { $_.Name -notin @('.', '..') }
            if ($files.Count -gt 0) {
                Write-Warning "Target [$targ] exists and is not empty. Skipping clone."
                Log-Err "Clone skipped for [$App], target [$targ] not empty."
                return
            }
        }
        try {
            git clone $Url $targ
            Write-Host "Clone successful for [$App]." -ForegroundColor Green
        }
        catch {
            Log-Err "Clone failed for [$App]: $_"
            Write-Error "Clone failed for [$App]: $_"
            return
        }
        # Post-clone steps for Fabric.
        if ($App -eq "fabric") {
            try {
                Push-Location $targ
                Write-Host "Running install_fabric.bat for Fabric..." -ForegroundColor Cyan
                cmd /c "install_fabric.bat"
                Pop-Location
                Write-Host "install_fabric.bat completed for Fabric." -ForegroundColor Green
            }
            catch {
                Log-Err "install_fabric.bat failed for Fabric: $_"
                Write-Error "install_fabric.bat failed for Fabric: $_"
            }
        }
    }
    else {
        # If an installer (EXE or MSI).
        if (-not (Test-Path $TEMP_DIR)) {
            try {
                New-Item -ItemType Directory -Path $TEMP_DIR -Force | Out-Null
                Write-Host "Created TEMP dir: $TEMP_DIR" -ForegroundColor Green
            }
            catch {
                Log-Err "Failed to create TEMP dir: $TEMP_DIR."
                Write-Error "Failed to create TEMP dir: $TEMP_DIR."
                return
            }
        }
        $ext = ([System.IO.Path]::GetExtension($Url)).ToLower()
        $name = "$App`_installer$ext"
        $installerPath = Join-Path $TEMP_DIR $name

        try {
            Write-Host "Downloading installer for [$App] from: $Url" -ForegroundColor Cyan
            $curlCmd = "curl.exe -L -o `"$installerPath`" `"$Url`""
            Invoke-Expression $curlCmd
            if (Test-Path $installerPath) {
                Write-Host "Downloaded installer for [$App] to: $installerPath" -ForegroundColor Green
            }
            else {
                Log-Err "Download failed for [$App]. File not found at: $installerPath"
                Write-Error "Download failed for [$App]."
                return
            }
        }
        catch {
            Log-Err "Error downloading installer for [$App]: $_"
            Write-Error "Error downloading installer for [$App]: $_"
            return
        }

        switch ($ext) {
            ".msi" {
                Write-Host "MSI installer detected for [$App]. Running msiexec..." -ForegroundColor Cyan
                try {
                    Start-Process msiexec.exe -ArgumentList "/i `"$installerPath`" /qn" -Wait -ErrorAction Stop
                    Write-Host "MSI install complete for [$App]." -ForegroundColor Green
                }
                catch {
                    Log-Err "MSI install failed for [$App]: $_"
                    Write-Error "MSI install failed for [$App]: $_"
                }
            }
            ".exe" {
                Write-Host "EXE installer detected for [$App]. Running installer..." -ForegroundColor Cyan
                try {
                    Start-Process $installerPath -Wait -ErrorAction Stop
                    Write-Host "EXE install complete for [$App]." -ForegroundColor Green
                }
                catch {
                    Log-Err "EXE install failed for [$App]: $_"
                    Write-Error "EXE install failed for [$App]: $_"
                }
            }
            default {
                Write-Warning "Unknown installer file type [$ext] for [$App]."
                Log-Err "Unknown file type [$ext] for [$App]."
            }
        }
    }

    # For Ollama, confirm installation completion.
    if ($App -eq "ollama") {
        do {
            $ans = Read-Host "Have you finished installing Ollama completely? (Y/n)"
        } while ($ans.ToUpper() -ne "Y")
    }
}
#endregion

#region Process Installs
foreach ($app in $instList) {
    if ($APP_INSTALLERS.ContainsKey($app)) {
        Inst-Prog -App $app -Url $APP_INSTALLERS[$app]
    }
    else {
        Write-Warning "No installer URL for [$app]."
        Log-Err "No installer URL defined for [$app]."
    }
}
#endregion

#region Update PATH
Upd-Path -Dir $GO_BASE -Scope "Machine"
Upd-Path -Dir $GO_BASE -Scope "User"
Upd-Path -Dir $FABRIC_BASE -Scope "Machine"
Upd-Path -Dir $FABRIC_BASE -Scope "User"
Upd-Path -Dir $GO_BIN -Scope "Machine"
Upd-Path -Dir $GO_BIN -Scope "User"
#endregion

#region Set LlmConfig
function Set-LlmConfig {
    Write-Host "Running LLM configuration..." -ForegroundColor Cyan
    try {
        Write-Host "Pulling LLM [$LLM] via ollama..."
        Start-Process -FilePath "ollama" -ArgumentList "pull $LLM" -Wait -NoNewWindow -ErrorAction Stop
        Write-Host "LLM pull successful." -ForegroundColor Green
    }
    catch {
        Log-Err "LLM pull failed: $_"
        Write-Error "LLM pull failed: $_"
    }
    Write-Host "Now running 'fabric --setup'. When prompted, manually enter all required sections." -ForegroundColor Yellow
    try {
        Start-Process -FilePath "fabric" -ArgumentList "--setup" -Wait -NoNewWindow -ErrorAction Stop
        Write-Host "Fabric setup complete." -ForegroundColor Green
    }
    catch {
        Log-Err "Fabric setup failed: $_"
        Write-Error "Fabric setup failed: $_"
    }
}


# ::============================================================================
# :: FUNCTION: TEST-OLLAMAMODEL
# ::============================================================================
# :: Performs a rudimentary check that Ollama model can be invoked. This is
# :: simplistic; real usage might prefer a direct invocation (Invoke-Expression).
# ::============================================================================
function Test-OllamaModel {
    Write-Output "Testing Ollama model load with ollama run $_LLM_..."
    try {
        $result = "ollama run $_LLM_"

        if ($result) {
            Write-Output "Ollama model $_LLM_ loaded successfully!"
        }
        else {
            Write-Output "Failed to load Ollama model $_LLM_!"
            Log-Error "Failed to load Ollama model $_LLM_."
            exit 1
        }
    }
    catch {
        Log-Error "Ollama model load failed: $_"
    }
}

# ::============================================================================
# :: FUNCTION: TEST-FABRICPIPING
# ::============================================================================
# :: Sends a test prompt ("What is the capital of France?") to fabric ask 
# :: and checks if "Paris" is in the output. 
# ::============================================================================
function Test-FabricPiping {
    Write-Output "Testing Fabric piping..."
    try {
        $testOutput = "What is the capital of France?"
        $pipeResult = $testOutput | fabric ask

        if ($pipeResult -like "*Paris*") {
            Write-Output "Fabric successfully processed the piped data."
        }
        else {
            Write-Output "Fabric did not process the data as expected."
            Log-Error "Fabric piping test failed: output did not contain 'Paris'."
            exit 1
        }
    }
    catch {
        Log-Error "Fabric piping test failed: $_"
        Write-Output "Fabric piping test failed."
        exit 1
    }
}

# Execute LLM configuration (requires Ollama installed).
Set-LlmConfig

# Test fabric via simple CLI pipe
Test-FabricPiping
#endregion

#region Summary Report
Write-Host "`n============================================" -ForegroundColor Cyan
Write-Host "          INSTALLATION SUMMARY              " -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host "Git installed at: $($gitCmd.Source)" -ForegroundColor Green
Write-Host "Go installed at: $GO_BASE" -ForegroundColor Green
Write-Host "Go bin directory: $GO_BIN" -ForegroundColor Green
Write-Host "Fabric installed at: $FABRIC_BASE" -ForegroundColor Green
Write-Host "LLM configured as: $LLM" -ForegroundColor Green
Write-Host "Temp installer directory: $TEMP_DIR" -ForegroundColor Green
Write-Host "Ensure PATH includes these directories (the script has persisted them)." -ForegroundColor Yellow
Write-Host "============================================`n" -ForegroundColor Cyan
#endregion

#region Refresh PATH & End
# Refresh the current shell PATH with updated values from Machine + User.
$env:PATH = [System.Environment]::GetEnvironmentVariable("PATH", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("PATH", "User")

Read-Host "Press Enter to exit"
#endregion
