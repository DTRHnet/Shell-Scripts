function Test-FileExists {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [string]$FilePath
    )
    
    try {
        return Test-Path -Path $FilePath -PathType Leaf
    }
    
    catch {
        Write-Log -LogFile "script.log" -Message "Error testing file existence for '$FilePath': $_" -LogLevel ERROR
        return $false
    }
}

function Write-Message {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [string]$Message,

        [Parameter()]
        [ValidateSet('Information', 'Warning', 'Error')]
        [string]$MessageType = 'Information',

        [Parameter()]
        [switch]$VerboseOutput
    )

    begin {
        # Ensure the output stream is properly initialized
        Write-Verbose "Initializing message output..."
    }

    process {
        switch ($MessageType) {
            'Information' { 
                if (($VerboseOutput) -or ($PSCmdlet.MyInvocation.BoundParameters['Verbose'])) {
                    Write-Host "[INFO] $Message" -ForegroundColor Cyan
                } else {
                    Write-Host "[INFO] $Message"
                }
            }
            'Warning' { 
                if (($VerboseOutput) -or ($PSCmdlet.MyInvocation.BoundParameters['Verbose'])) {
                    Write-Host "[WARNING] $Message" -ForegroundColor Yellow
                } else {
                    Write-Host "[WARNING] $Message"
                }
            }
            'Error' {
                if (($VerboseOutput) -or ($PSCmdlet.MyInvocation.BoundParameters['Verbose'])) {
                    Write-Host "[ERROR] $Message" -ForegroundColor Red
                } else {
                    Write-Host "[ERROR] $Message"
                }
            }
        }
    }

    end {
        Write-Verbose "Message output completed."
    }
}

function Invoke-DryRun {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [scriptblock]$ScriptBlock,

        [Parameter()]
        [switch]$DryRun
    )

    if ($DryRun) {
        Write-Host "[DRY-RUN] Simulating the script execution..." -ForegroundColor Cyan
        Write-Output "[DRY-RUN] Actions that would be performed:" 
        & $ScriptBlock | ForEach-Object { Write-Host "[DRY-RUN] $_" -ForegroundColor Green }
    } else {
        Write-Host "Executing the script..." -ForegroundColor Cyan
        & $ScriptBlock
    }
}

function Confirm-UserChoice {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [string]$Prompt,
        [Parameter()]
        [bool]$DefaultChoice = $true
    )
    
    $defaultText = if ($DefaultChoice) { "[Y]/n" } else { "y/[N]" }
    while ($true) {
        $uInput = Read-Host "$Prompt ($defaultText)"
        $response = $uInput.Trim().ToLower()

        if ([string]::IsNullOrWhiteSpace($response)) {
            return $DefaultChoice
        }
        elseif ($response -eq "y" -or $response -eq "yes") {
            return $true
        }
        elseif ($response -eq "n" -or $response -eq "no") {
            return $false
        }
        else {
            # Use Write-Host directly for simplicity, or your Write-Message if desired
            Write-Host "Invalid input. Please enter yes or no." -ForegroundColor Yellow
        }
    }
}

function Set-OperationStatus {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$StateFile,

        [Parameter(Mandatory = $true)]
        [int]$Section,

        [Parameter(Mandatory = $true)]
        [ValidateSet('Success', 'Failure')]
        [string]$Status
    )

    # Ensure the directory for the state file exists
    $dir = Split-Path $StateFile
    if (-not (Test-Path $dir)) {
        try {
            New-Item -ItemType Directory -Path $dir -Force | Out-Null
            Write-Verbose "Created directory $dir for state file."
        } catch {
            Write-Error "Failed to create directory '$dir': $_"
            return
        }
    }

    # Create the state file if it doesn't exist
    if (-not (Test-Path $StateFile)) {
        try {
            New-Item -Path $StateFile -ItemType File -Force | Out-Null
            $stateData = @{}
            try {
                $jsonData = $stateData | ConvertTo-Json -Depth 10
                Set-Content -Path $StateFile -Value $jsonData -Encoding UTF8 -Force
            } catch {
                Write-Error "Failed to initialize state file: $_"
                return
            }
        } catch {
            Write-Error "Unable to create state tracking file: $_"
            return
        }
    }

    # Initalize an empty hashtable for state data
    $stateData = @{}

    # Attempt to read the state file content
    try {
        $content = Get-Content $StateFile -Raw -Encoding UTF8
    } catch {
        Write-Error "Failed to read state file: $_"
        return
    }

    # If the file is empty or whitespace, log info; otherwise, try to parse JSON
    if ([string]::IsNullOrWhiteSpace($content)) {
        Write-Host "[INFO] State file is empty. Initializing new state data." -ForegroundColor Yellow
    } else {
        try {
            # Use appropriate JSON conversion depending on PowerShell version
            if ($PSVersionTable.PSVersion.Major -ge 6) {
                $stateData = $content | ConvertFrom-Json -AsHashtable
            } else {
                $parsedObject = $content | ConvertFrom-Json
                # Convert PSCustomObject to hashtable for compatibility
                $stateData = @{}
                foreach ($prop in $parsedObject.PSObject.Properties) {
                    $stateData[$prop.Name] = $prop.Value
                }
            }
            if (-not $stateData) {
                $stateData = @{}
            }
        } catch {
            # Backup the current malformed state file
            $backupFile = "$StateFile.bak_$(Get-Date -Format yyyyMMddHHmmss)"
            try {
                Copy-Item -Path $StateFile -Destination $backupFile -Force
                Write-Host "[WARNING] Backup created at '$backupFile' due to parse error." -ForegroundColor Yellow
            } catch {
                Write-Host "[ERROR] Could not backup the malformed state file: $_" -ForegroundColor Red
            }
            Write-Host "[ERROR] Failed to parse state file. Resetting contents." -ForegroundColor Red
            $stateData = @{}
        }
    }

    # Update the state data for the specified section
    $stateData["Section$Section"] = $Status

    # Attempt to write the updated state back to the file
    try {
        $newContent = $stateData | ConvertTo-Json -Depth 10
        Set-Content -Path $StateFile -Value $newContent -Encoding UTF8 -Force
        Write-Host "[INFO] Recorded section $Section with status '$Status'." -ForegroundColor Green
    } catch {
        Write-Error "Failed to write updated state to file: $_"
        return
    }

    # If the status indicates failure, log error and exit
    if ($Status -eq 'Failure') {
        Write-Host "[ERROR] Section $Section failed. Stopping execution." -ForegroundColor Red
        exit 1
    }
}

function Write-Log {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [string]$LogFile,

        [Parameter(Mandatory=$true)]
        [string]$Message,

        [Parameter()]
        [ValidateSet('INFO', 'WARNING', 'ERROR')]
        [string]$LogLevel = 'INFO'
    )

    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = "$timestamp [$LogLevel] $Message"

    try {
        # Open the file with shared read/write access
        $fileStream = [System.IO.File]::Open($LogFile, [System.IO.FileMode]::Append, [System.IO.FileAccess]::Write, [System.IO.FileShare]::ReadWrite)
        $streamWriter = New-Object System.IO.StreamWriter($fileStream)
        $streamWriter.WriteLine($logEntry)
        $streamWriter.Close()
        Write-Host "[LOG] $logEntry" -ForegroundColor Gray
    }
    catch {
        Write-Host "[ERROR] Failed to write to log file '$LogFile': $_" -ForegroundColor Red
    }
}

function Get-ByDL {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [string]$Url,

        [Parameter(Mandatory=$true)]
        [string]$DestinationPath,

        [Parameter()]
        [int]$MaxRetries = 3,

        [Parameter()]
        [int]$DelayBetweenRetriesSeconds = 5
    )

    <#
    .SYNOPSIS
        Downloads a file with retry logic.
    .DESCRIPTION
        Attempts to download a file from the given URL, retrying up to MaxRetries times upon failure.
    #>

    $attempt = 0
    while ($attempt -lt $MaxRetries) {
        try {
            Write-Message -Message "Attempting to download $Url to $DestinationPath (Attempt $($attempt + 1))" -MessageType Information
            Invoke-WebRequest -Uri $Url -OutFile $DestinationPath -ErrorAction Stop
            Write-Message -Message "Download successful." -MessageType Information
            return $true
        }
        catch {
            Write-Log -LogFile "script.log" -Message "Download failed on attempt $($attempt + 1): $_" -LogLevel WARNING
            $attempt++
            if ($attempt -lt $MaxRetries) {
                Write-Message -Message "Retrying in $DelayBetweenRetriesSeconds seconds..." -MessageType Warning
                Start-Sleep -Seconds $DelayBetweenRetriesSeconds
            }
        }
    }

    Write-Log -LogFile "script.log" -Message "Failed to download file after $MaxRetries attempts." -LogLevel ERROR
    return $false
}

function Test-AdminRights {
    [CmdletBinding()]
    param ()
    <#
    .SYNOPSIS
        Checks if the current PowerShell session has administrative privileges.
    .DESCRIPTION
        Determines if the current session is running as administrator.
    #>
    try {
        $currentIdentity = [Security.Principal.WindowsIdentity]::GetCurrent()
        $principal = New-Object Security.Principal.WindowsPrincipal($currentIdentity)
        return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    }
    catch {
        Write-Host "Failed to determine admin rights: $_" -ForegroundColor Red
        return $false
    }
}
