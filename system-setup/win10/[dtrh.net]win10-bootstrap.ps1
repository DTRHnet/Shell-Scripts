# DTRH.ps1

# Dot-source the utility functions file containing all utility functions
. "$PSScriptRoot\utility.ps1"

# Validate that critical functions are available
if (-not (Get-Command Test-AdminRights -ErrorAction SilentlyContinue)) {
    Write-Host "Critical function Test-AdminRights not found. Check utility.ps1 path and contents." -ForegroundColor Red
    exit 1
}

function Start-Hardener {
    [CmdletBinding()]
    param (
        [switch]$DryRun,
        [switch]$VerboseOutput
    )

    Write-Log -LogFile $global:logFile -Message "Entering Start-Hardener function." -LogLevel INFO

    # Ensure administrative privileges
    if (-not (Test-AdminRights)) {
        Write-Message -Message "This script requires administrative privileges. Please run as administrator." -MessageType Error -VerboseOutput:$VerboseOutput
        Write-Log -LogFile $global:logFile -Message "Administrative privileges not detected. Exiting Start-Hardener." -LogLevel ERROR
        exit 1
    }
    Write-Log -LogFile $global:logFile -Message "Administrative privileges confirmed." -LogLevel INFO

    # Display terminal title
    Write-TerminalTitle -Stage "STAGE 1" -Text "System Hardening" -VerboseOutput:$VerboseOutput
    Write-Log -LogFile $global:logFile -Message "Displayed terminal title for Stage 1." -LogLevel INFO

    # Define URLs and file paths
    $url1 = "https://raw.githubusercontent.com/atlantsecurity/windows-hardening-scripts/refs/heads/main/Windows-10-Hardening-script.cmd"
    $url2 = "https://gist.githubusercontent.com/alirobe/7f3b34ad89a159e6daa1/raw/6fd7af7f49692ffb7120ee72f6abbb7883102040/reclaimWindows10.ps1"

    $destinationFolder = Join-Path -Path $PSScriptRoot -ChildPath "hardening"
    $scriptPath1 = Join-Path -Path $destinationFolder -ChildPath "hardener.cmd"
    $scriptPath2 = Join-Path -Path $destinationFolder -ChildPath "blacklist.ps1"

    Write-Log -LogFile $global:logFile -Message "Set download paths: `n 1) $scriptPath1 `n 2) $scriptPath2" -LogLevel INFO

    # Ensure hardening directory exists
    if (-not (Test-Path $destinationFolder)) {
        try {
            New-Item -ItemType Directory -Path $destinationFolder -Force | Out-Null
            Write-Message -Message "Created directory $destinationFolder" -VerboseOutput:$VerboseOutput
            Write-Log -LogFile $global:logFile -Message "Created directory $destinationFolder." -LogLevel INFO
        }
        catch {
            Write-Message -Message "Error creating directory: $_" -MessageType Error -VerboseOutput:$VerboseOutput
            Write-Log -LogFile $global:logFile -Message "Error creating directory: $_" -LogLevel ERROR
            return
        }
    }

    # Download first script
    Write-Message -Message "Downloading first script from $url1 to $scriptPath1" -VerboseOutput:$VerboseOutput
    Write-Log -LogFile $global:logFile -Message "Downloading first script from $url1" -LogLevel INFO

    if (-not $DryRun) {
        if (-not (Download-FileWithRetry -Url $url1 -DestinationPath $scriptPath1 -MaxRetries 3)) {
            Write-Message -Message "Failed to download first script." -MessageType Error -VerboseOutput:$VerboseOutput
            Write-Log -LogFile $global:logFile -Message "Failed to download first script from $url1." -LogLevel ERROR
            return
        }
        Write-Log -LogFile $global:logFile -Message "Successfully downloaded first script." -LogLevel INFO
    }

    # Execute first script
    Write-Message -Message "Executing first script..." -VerboseOutput:$VerboseOutput
    Write-Log -LogFile $global:logFile -Message "Executing first script at $scriptPath1." -LogLevel INFO

    $cmdProcess = Start-Process -FilePath "cmd.exe" -ArgumentList "/c `"$scriptPath1`"" -WorkingDirectory $destinationFolder -NoNewWindow -Wait -PassThru

    if ($cmdProcess.ExitCode -ne 0) {
        Write-Message -Message "Error: First script execution failed." -MessageType Error -VerboseOutput:$VerboseOutput
        Write-Log -LogFile $global:logFile -Message "First script execution failed with exit code $($cmdProcess.ExitCode)." -LogLevel ERROR
        Set-OperationStatus -StateFile $global:stateFile -Section 1 -Status Failure
        return
    }
    Write-Log -LogFile $global:logFile -Message "First script executed successfully." -LogLevel INFO

    # Download second script
    Write-Message -Message "Downloading second script from $url2 to $scriptPath2" -VerboseOutput:$VerboseOutput
    Write-Log -LogFile $global:logFile -Message "Downloading second script from $url2" -LogLevel INFO

    if (-not $DryRun) {
        if (-not (Download-FileWithRetry -Url $url2 -DestinationPath $scriptPath2 -MaxRetries 3)) {
            Write-Message -Message "Failed to download second script." -MessageType Error -VerboseOutput:$VerboseOutput
            Write-Log -LogFile $global:logFile -Message "Failed to download second script from $url2." -LogLevel ERROR
            return
        }
        Write-Log -LogFile $global:logFile -Message "Successfully downloaded second script." -LogLevel INFO
    }

    # Execute second script
    Write-Message -Message "Executing second script..." -VerboseOutput:$VerboseOutput
    Write-Log -LogFile $global:logFile -Message "Executing second script at $scriptPath2." -LogLevel INFO

    $psProcess = Start-Process -FilePath "powershell.exe" -ArgumentList "-ExecutionPolicy Bypass -File `"$scriptPath2`"" -WorkingDirectory $destinationFolder -NoNewWindow -Wait -PassThru

    if ($psProcess.ExitCode -ne 0) {
        Write-Message -Message "Error: Second script execution failed." -MessageType Error -VerboseOutput:$VerboseOutput
        Write-Log -LogFile $global:logFile -Message "Second script execution failed with exit code $($psProcess.ExitCode)." -LogLevel ERROR
        Set-OperationStatus -StateFile $global:stateFile -Section 2 -Status Failure
        return
    }

    # Set operation status to success (before restart)
    Write-Log -LogFile $global:logFile -Message "Second script executed successfully. Setting state before reboot." -LogLevel INFO
    Set-OperationStatus -StateFile $global:stateFile -Section 2 -Status Success

    Write-Message -Message "Both scripts executed successfully. System will now restart." -VerboseOutput:$VerboseOutput
    Write-Log -LogFile $global:logFile -Message "Both scripts executed successfully. System will now restart." -LogLevel INFO

    Write-Log -LogFile $global:logFile -Message "Exiting Start-Hardener function." -LogLevel INFO
}
   

function DTRH {
    [CmdletBinding()]
    param(
        [switch]$DryRun,
        [switch]$VerboseOutput
    )

    # Define logs directory and log file
    $logDir = Join-Path -Path $PSScriptRoot -ChildPath "logs"
    if (-not (Test-Path $logDir)) {
        try {
            New-Item -ItemType Directory -Path $logDir -Force | Out-Null
            Write-Host "Created logs directory at $logDir."
        }
        catch {
            Write-Host "Error creating logs directory: $_" -ForegroundColor Red
            exit 1
        }
    }

    $logFileName = "log_" + (Get-Date -Format "yyyyMMdd") + ".log"
    $logFile = Join-Path -Path $logDir -ChildPath $logFileName
    $stateFile = Join-Path -Path $PSScriptRoot -ChildPath "state.json"

    # Assign logFile and stateFile to global variables for access in functions
    $global:logFile = $logFile
    $global:stateFile = $stateFile

    Write-Log -LogFile $logFile -Message "Starting DTRH process." -LogLevel INFO

    try {
        Start-Hardener -VerboseOutput:$VerboseOutput -DryRun:$DryRun
        Write-Log -LogFile $logFile -Message "Completed Start-Hardener successfully." -LogLevel INFO
    }
    catch {
        Write-Log -LogFile $logFile -Message "Error in Start-Hardener: $_" -LogLevel ERROR
        Write-Message -Message "An error occurred during the bootstrap process. Check the log file for details." -MessageType Error -VerboseOutput:$VerboseOutput
        exit 1
    }

    Write-Log -LogFile $logFile -Message "Completed DTRH process." -LogLevel INFO
}

# Initiate the bootstrap process with desired switches
DTRH -VerboseOutput 
