param(
    [switch]$Interactive
)

#region Log & Stop
# Log errors verbosely to errors.log with timestamp.
function Log-Err {
    param(
        [Parameter(Mandatory=$true)]
        [string]$Msg
    )
    $time = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $line = "$time - $Msg"
    Add-Content -Path "errors.log" -Value $line
}

# Stop the script (without closing the shell).
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

#region Broadcast Env Changes
# This function sends a WM_SETTINGCHANGE message to inform other processes
# of environment variable updates. This makes PATH changes more likely to be
# recognized by newly started programs.
function BC-Env {
    Add-Type -TypeDefinition @"
using System;
using System.Runtime.InteropServices;

public class EnvRefresher {
    [DllImport("user32.dll", CharSet=CharSet.Auto, SetLastError=true)]
    public static extern IntPtr SendMessageTimeout(IntPtr hWnd, int Msg,
        IntPtr wParam, IntPtr lParam, int flags, int timeout, out IntPtr result);

    public const int HWND_BROADCAST = 0xffff;
    public const int WM_SETTINGCHANGE = 0x1A;
    public static void Refresh() {
        IntPtr res;
        SendMessageTimeout((IntPtr)HWND_BROADCAST, WM_SETTINGCHANGE,
            IntPtr.Zero, IntPtr.Zero, 2, 500, out res);
    }
}
"@
    [EnvRefresher]::Refresh()
    Write-Host "Broadcasted WM_SETTINGCHANGE message to refresh environment variables." -ForegroundColor Green
}
#endregion

#region Constants
# Define apps to check (git is required for fabric).
$APP_DEPS = @("git", "go", "fabric", "ollama")

# Define installer URLs.
# A URL ending with .git or containing github.com is treated as a repo link.
$APP_INSTALLERS = @{
    "git"    = "https://github.com/git-for-windows/git/releases/download/v2.41.0.windows.1/Git-2.41.0-64-bit.exe"
    "go"     = "https://golang.org/dl/go1.21.0.windows-amd64.msi"
    "fabric" = "https://github.com/fabric/fabric.git"
    "ollama" = "https://ollama.ai/win/ollama_installer.exe"
}

# Default install paths.
$GO_BASE     = "C:\Go"                              # Where Go is installed.
$FABRIC_BASE = "$env:USERPROFILE\fabric"            # Where Fabric repo is cloned.
$TEMP_DIR    = "C:\Temp"                            # Where EXE/MSI installers are downloaded.
$GO_BIN      = "$env:USERPROFILE\go\bin"            # Go binary folder.
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

#region Update PATH Func
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
            $new = $cur + ";" + $Dir
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
            $new = $cur + ";" + $Dir
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

#region Install Func: Inst-Prog
function Inst-Prog {
    param(
        [Parameter(Mandatory=$true)]
        [string]$App,
        [Parameter(Mandatory=$true)]
        [string]$Url
    )
    Write-Host "Installing [$App]..." -ForegroundColor Cyan

    # If URL is a repo link.
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
            $its = Get-ChildItem $targ -Force | Where-Object { $_.Name -notin @('.', '..') }
            if ($its.Count -gt 0) {
                Write-Warning "Target [$targ] exists and is not empty. Skipping clone."
                Log-Err "Clone skipped for [$App] as target [$targ] is not empty."
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
        # For fabric, run install_fabric.bat in the cloned directory.
        if ($App -eq "fabric") {
            try {
                Push-Location $targ
                Write-Host "Running install_fabric.bat for [$App]..." -ForegroundColor Cyan
                cmd /c "install_fabric.bat"
                Pop-Location
                Write-Host "install_fabric.bat completed for [$App]." -ForegroundColor Green
            }
            catch {
                Log-Err "install_fabric.bat failed for [$App]: $_"
                Write-Error "install_fabric.bat failed for [$App]: $_"
            }
        }
    }
    else {
        # For installer files, download to $TEMP_DIR.
        if (-not (Test-Path $TEMP_DIR)) {
            try {
                New-Item -ItemType Directory -Path $TEMP_DIR -Force | Out-Null
                Write-Host "Created TEMP dir: $TEMP_DIR" -ForegroundColor Green
            }
            catch {
                Log-Err "Failed to create TEMP dir: $TEMP_DIR. Skipping [$App]."
                Write-Error "Failed to create TEMP dir: $TEMP_DIR. Skipping [$App]."
                return
            }
        }
        $ext = ([System.IO.Path]::GetExtension($Url)).ToLower()
        $name = "$App`_installer$ext"
        $path = Join-Path $TEMP_DIR $name

        try {
            Write-Host "Downloading installer for [$App] from: $Url" -ForegroundColor Cyan
            $curlCmd = "curl.exe -L -o `"$path`" `"$Url`""
            Invoke-Expression $curlCmd
            if (Test-Path $path) {
                Write-Host "Downloaded installer for [$App] to: $path" -ForegroundColor Green
            }
            else {
                Log-Err "Download failed for [$App]. Installer file not found at: $path"
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
                Write-Host "MSI installer detected for [$App]. Running msiexec." -ForegroundColor Cyan
                try {
                    Start-Process -FilePath "msiexec.exe" -ArgumentList "/i `"$path`" /qn" -Wait -ErrorAction Stop
                    Write-Host "MSI install complete for [$App]." -ForegroundColor Green
                }
                catch {
                    Log-Err "MSI install failed for [$App]: $_"
                    Write-Error "MSI install failed for [$App]: $_"
                }
            }
            ".exe" {
                Write-Host "EXE installer detected for [$App]. Running installer." -ForegroundColor Cyan
                try {
                    Start-Process -FilePath $path -Wait -ErrorAction Stop
                    Write-Host "EXE install complete for [$App]." -ForegroundColor Green
                }
                catch {
                    Log-Err "EXE install failed for [$App]: $_"
                    Write-Error "EXE install failed for [$App]: $_"
                }
            }
            default {
                Write-Warning "Unknown file type [$ext] for [$App]."
                Log-Err "Unknown file type [$ext] for [$App]."
            }
        }
    }
    
    # For ollama, prompt the user to confirm installation completion.
    if ($App -eq "ollama") {
        do {
            $ans = Read-Host "Have you finished installing Ollama? Y/n"
        } while ($ans -notin @("Y","y"))
    }
}
#endregion

#region Process Install List
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

#region Update PATH for Install Bases
# Update System/User PATH for go, fabric, and go\bin.
Upd-Path -Dir $GO_BASE     -Scope "Machine"
Upd-Path -Dir $GO_BASE     -Scope "User"
Upd-Path -Dir $FABRIC_BASE -Scope "Machine"
Upd-Path -Dir $FABRIC_BASE -Scope "User"
Upd-Path -Dir $GO_BIN      -Scope "Machine"
Upd-Path -Dir $GO_BIN      -Scope "User"

# Broadcast WM_SETTINGCHANGE so newly launched processes see updated environment.
BC-Env
#endregion

#region Summary Report & Refresh
Write-Host "============================================" -ForegroundColor Cyan
Write-Host "          INSTALLATION SUMMARY              " -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host "Git installed at: $($gitCmd.Source)" -ForegroundColor Green
Write-Host "Go installed at: $GO_BASE" -ForegroundColor Green
Write-Host "Go BIN at: $GO_BIN" -ForegroundColor Green
Write-Host "Fabric installed at: $FABRIC_BASE" -ForegroundColor Green
Write-Host "TEMP directory used: $TEMP_DIR" -ForegroundColor Green
Write-Host "Paths have been updated and WM_SETTINGCHANGE broadcasted." -ForegroundColor Yellow
Write-Host "If a new terminal does not see these changes, please log out or re-launch" -ForegroundColor Yellow
Write-Host "from Windows Explorer (or restart your terminal application)." -ForegroundColor Yellow
Write-Host "============================================" -ForegroundColor Cyan

# Refresh current shell's PATH so this session also sees the updated PATH right away.
$env:PATH = [Environment]::GetEnvironmentVariable("PATH","Machine") + ";" + [Environment]::GetEnvironmentVariable("PATH","User")
#endregion

Read-Host "Press Enter to exit"
