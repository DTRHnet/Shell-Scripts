#!/usr/bin/env pwsh
################################################################################
# Cross-Platform Setup Script (PowerShell)
#
# This script will:
#   1) Detect the OS (Windows, Linux, macOS) using .NET's RuntimeInformation.
#   2) Install required dependencies: git, curl, go, ollama.
#      (Linux uses apt-get with special handling for Go and Ollama.)
#   3) Clone the Fabric repository into a folder named "fabric-main" in the
#      current directory and then change into the "fabric-main/fabric-main"
#      subdirectory before building.
#   4) Export the PATH for Go and Fabric on Linux/macOS (both for the current
#      session and by appending to the shell RC file).
#   5) Configure Ollama to use the default model ($LLM) and test it.
#   6) Run "fabric --setup" to allow manual setup of patterns and model,
#      display a bold warning, and prompt the user to confirm that setup is
#      complete before continuing.
#   7) Test Fabric piping by sending a test query.
#
# All actions are logged and output is divided into clearly marked sections.
################################################################################

# ----------------------------------------------------------------------------
# Global Variables
# ----------------------------------------------------------------------------
$ErrorLog      = "error.log"                       # Error log file location
$Dependencies  = @("git", "curl", "go", "ollama")   # Dependencies to check/install
$InstallList   = @()                               # Missing dependencies list
$FabricRepo    = "https://github.com/danielmiessler/fabric.git"
$FabricPath    = ""                                # Full path to Fabric's build folder
$LLM           = "deepseek-r1"                     # Default model name for Ollama
$OS            = ""                                # Detected OS

# ----------------------------------------------------------------------------
# Function: Init-ErrorLog
# ----------------------------------------------------------------------------
function Init-ErrorLog {
    if (-not (Test-Path $ErrorLog)) {
        # Create the error log file if it does not exist.
        New-Item -Path $ErrorLog -ItemType File | Out-Null
    }
}

# ----------------------------------------------------------------------------
# Function: Log-Error
# ----------------------------------------------------------------------------
function Log-Error {
    param ([string]$Message)
    # Append an error message with a timestamp to the error log.
    $Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    "$Timestamp - ERROR: $Message" | Out-File -FilePath $ErrorLog -Append
}

# ----------------------------------------------------------------------------
# Function: Detect-OS
# ----------------------------------------------------------------------------
function Detect-OS {
    # Use .NET RuntimeInformation for reliable OS detection.
    if ([System.Runtime.InteropServices.RuntimeInformation]::IsOSPlatform([System.Runtime.InteropServices.OSPlatform]::Windows)) {
        $global:OS = "Windows"
        # For Windows, build FabricPath using backslashes.
        $global:FabricPath = "$(Get-Location)\fabric-main"
    }
    elseif ([System.Runtime.InteropServices.RuntimeInformation]::IsOSPlatform([System.Runtime.InteropServices.OSPlatform]::Linux)) {
        $global:OS = "Linux"
        # For Linux, use forward slashes.
        $global:FabricPath = "$(Get-Location)/fabric-main"
    }
    elseif ([System.Runtime.InteropServices.RuntimeInformation]::IsOSPlatform([System.Runtime.InteropServices.OSPlatform]::OSX)) {
        $global:OS = "Mac"
        # For macOS, also use forward slashes.
        $global:FabricPath = "$(Get-Location)/fabric-main"
    }
    else {
        $global:OS = "Unsupported"
        Write-Output "If you are using TempleOS, fabric is written in GoLang and thus it would be a sin to use."
        exit 1
    }
    Write-Output "-----------------------------------------"
    Write-Output "Detected OS: $OS"
    Write-Output "-----------------------------------------"
}

# ----------------------------------------------------------------------------
# Function: Check-Dependency
# ----------------------------------------------------------------------------
function Check-Dependency {
    param ([string]$Program)
    # Check if the command exists; if not, add it to the missing list.
    if (-not (Get-Command $Program -ErrorAction SilentlyContinue)) {
        $global:InstallList += $Program
        return $false
    }
    return $true
}

# ----------------------------------------------------------------------------
# Function: Install-Dependencies
# ----------------------------------------------------------------------------
function Install-Dependencies {
    param ([string[]]$Deps)
    Write-Output "-----------------------------------------"
    Write-Output "Installing Missing Dependencies"
    Write-Output "-----------------------------------------"
    foreach ($dep in $Deps) {
        if (-not (Check-Dependency $dep)) {
            Write-Output "Installing $dep..."
            switch ($OS) {
                "Linux" {
                    # Update apt and install dependency.
                    sudo apt-get update
                    sudo apt-get install -y $dep
                    # Special handling: For Ollama, run its install script.
                    if ($dep -eq "ollama") {
                        curl -fsSL https://ollama.com/install.sh | sh
                    }
                }
                "Mac" {
                    # Ensure Homebrew is installed and then use it.
                    if (-not (Get-Command brew -ErrorAction SilentlyContinue)) {
                        Write-Output "Homebrew not found. Installing Homebrew..."
                        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
                    }
                    brew install $dep
                }
                "Windows" {
                    switch ($dep) {
                        "git"    { Start-Process "https://git-scm.com/download/win" -Wait }
                        "go"     { Start-Process "https://go.dev/dl/go1.24.0.windows-amd64.msi" -Wait }
                        "curl"   { Write-Output "curl is typically pre-installed on Windows 10+." }
                        "ollama" { Start-Process "https://ollama.com/download/OllamaSetup.exe" -Wait }
                        default  { Write-Output "No installer found for $dep." }
                    }
                }
                default {
                    Log-Error "Unsupported OS during dependency installation."
                    Write-Output "Cannot install on unsupported OS."
                    exit 1
                }
            }
        }
        else {
            Write-Output "$dep is already installed."
        }
    }
    Write-Output "Dependency installation complete."
}

# ----------------------------------------------------------------------------
# Function: Install-Fabric
# ----------------------------------------------------------------------------
function Install-Fabric {
    Write-Output "-----------------------------------------"
    Write-Output "Cloning and Installing Fabric"
    Write-Output "-----------------------------------------"
    try {
        # Clone the Fabric repo into a folder named "fabric-main".
        git clone $FabricRepo fabric-main
        # Change into the designated build folder.
        Set-Location $FabricPath
        Write-Output "Building Fabric using Go..."
        go install .
        if ($OS -eq "Windows") {
            # On Windows, append the Go bin path to the current session.
            $env:PATH = $env:PATH + ";" + $env:GOPATH + "\bin"
        }
        else {
            # On Linux/macOS, update the PATH persistently.
            Export-Paths
        }
        Write-Output "Fabric installed successfully."
    }
    catch {
        Log-Error "Failed to install Fabric: $_"
        Write-Output "Failed to install Fabric. Check error.log for details."
        exit 1
    }
}

# ----------------------------------------------------------------------------
# Function: Export-Paths
# ----------------------------------------------------------------------------
function Export-Paths {
    Write-Output "-----------------------------------------"
    Write-Output "Exporting Go and Fabric Paths"
    Write-Output "-----------------------------------------"
    # Typical Go installation path on Linux/macOS.
    $GoBin = "/usr/local/go/bin"
    # Default location for binaries installed by 'go install'.
    $FabricBin = "$HOME/go/bin"
    # Determine which shell config file to use (zsh or bash).
    $ShellRC = if ($SHELL -like "*zsh") { "$HOME/.zshrc" } else { "$HOME/.bashrc" }
    # 1) Update the current session's PATH.
    $env:PATH = "$($env:PATH):${GoBin}:${FabricBin}"
    # 2) Append an export command to the shell configuration file.
    $ExportCmd = "export PATH=${PATH}:${GoBin}:${FabricBin}"
    Add-Content -Path $ShellRC -Value $ExportCmd
    Write-Output "Paths have been exported to $ShellRC."
    Write-Output "Please restart your terminal or run: source $ShellRC"
}

# ----------------------------------------------------------------------------
# Function: Set-OllamaModel
# ----------------------------------------------------------------------------
# Downloads the desired model for Ollama using "ollama pull $LLM".
# This function ensures that the model ($LLM) is downloaded.
# ----------------------------------------------------------------------------
function Set-OllamaModel {
    Write-Output "-----------------------------------------"
    Write-Output "Downloading Ollama model: $LLM"
    Write-Output "-----------------------------------------"
    try {
        # Execute the command to pull the model
        & ollama pull $LLM
        Write-Output "Ollama model $LLM downloaded successfully."
    }
    catch {
        Log-Error "Failed to download Ollama model ${LLM}: $_"
        Write-Output "Error downloading Ollama model $LLM."
        exit 1
    }
}


# ----------------------------------------------------------------------------
# Function: Test-OllamaModel
# ----------------------------------------------------------------------------
function Test-OllamaModel {
    Write-Output "-----------------------------------------"
    Write-Output "Testing Ollama Model"
    Write-Output "-----------------------------------------"
    try {
        # Execute the command and capture output.
        $result = "$(echo "2 + 2 equals" | ollama run $LLM)"
        if ($result) {
            Write-Output "Ollama model $LLM loaded successfully!"
        }
        else {
            Write-Output "Failed to load Ollama model $LLM!"
            Log-Error "Failed to load Ollama model $LLM."
            exit 1
        }
    }
    catch {
        Log-Error "Ollama model load failed: $_"
        Write-Output "Error running Ollama model."
        exit 1
    }
}

# ----------------------------------------------------------------------------
# Function: Setup-FabricPatterns
# ----------------------------------------------------------------------------
# Runs "fabric --setup" to allow manual configuration of patterns and model.
# Displays a bold notice that manual setup is required and prompts the user
# to confirm that all setup is complete before continuing.
# ----------------------------------------------------------------------------
function Setup-FabricPatterns {
    Write-Output "-----------------------------------------"
    Write-Output "Fabric Manual Setup Required"
    Write-Output "-----------------------------------------"
    Write-Output "**IMPORTANT: You MUST manually set up Fabric patterns and select a model.**"
    Write-Output "**All required setup must be complete before continuing.**"
    # Run the interactive Fabric setup.
    fabric --setup
    # Prompt the user to confirm that setup is complete.
    $confirmation = Read-Host "Have you finished setting up Fabric's patterns and chosen a model? (y/n)"
    if ($confirmation -ne "y") {
        Write-Output "Setup not confirmed. Exiting script."
        exit 1
    }
    Write-Output "Fabric patterns and model setup confirmed. Continuing..."
}

# ----------------------------------------------------------------------------
# Function: Test-FabricPiping
# ----------------------------------------------------------------------------
function Test-FabricPiping {
    Write-Output "-----------------------------------------"
    Write-Output "Testing Fabric Piping"
    Write-Output "-----------------------------------------"
    try {
        $testOutput = "What is the capital of France?"
        # Pipe the test query into Fabric.
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

# ----------------------------------------------------------------------------
# Function: Run-Setup
# ----------------------------------------------------------------------------
function Run-Setup {
    Write-Output "========================================="
    Write-Output "Starting Cross-Platform Fabric Setup"
    Write-Output "========================================="

    # Step 1: Initialize error logging.
    Init-ErrorLog

    # Step 2: Detect the operating system.
    Detect-OS

    # Step 3: Check and install dependencies.
    Write-Output "-----------------------------------------"
    Write-Output "Checking Dependencies"
    Write-Output "-----------------------------------------"
    foreach ($dep in $Dependencies) {
        Check-Dependency $dep | Out-Null
    }
    if ($InstallList.Count -eq 0) {
        Write-Output "All dependencies are already installed."
    }
    else {
        $missing = $InstallList -join ", "
        Write-Output "Missing dependencies: $missing"
        Install-Dependencies -Deps $InstallList
    }

    # Step 4: Clone and install Fabric.
    Install-Fabric

    # Step 5: Configure and test Ollama.
    Set-OllamaModel
    Test-OllamaModel

    # Step 6: Run Fabric's interactive setup and verify manual configuration.
    Setup-FabricPatterns

    # Step 7: Test Fabric piping functionality.
    Test-FabricPiping

    Write-Output "========================================="
    Write-Output "Fabric Setup Complete!"
    Write-Output "========================================="
}

# ----------------------------------------------------------------------------
# Script Entry Point
# ----------------------------------------------------------------------------
Run-Setup
