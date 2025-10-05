$script:LogFilePath = $null

function Set-LogFilePath {
    param (
        [string]$Path
    )
    $script:LogFilePath = $Path
}

function Write-Log {
    param (
        [Parameter(Mandatory = $true)]
        [string]$Level,
        [Parameter(Mandatory = $true)]
        [string]$Message
    )

    if (-not $script:LogFilePath) {
        throw "LogFilePath not set. Call Set-LogFilePath first."
    }

    $Timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    $LogEntry = "$Timestamp - [$Level] $Message"
    $LogEntry | Out-File -FilePath $script:LogFilePath -Append -Encoding Unicode
}

function Show-MessageBox {
    param (
        [string]$Message,
        [string]$Title = "Notice",
        [ValidateSet("Information", "Warning", "Error", "Question")]
        [string]$Icon = "Information",
        [System.Windows.Forms.MessageBoxButtons]$Buttons = [System.Windows.Forms.MessageBoxButtons]::OK
    )

    # Create a hidden "topmost" window to own the message box
    $Form = New-Object System.Windows.Forms.Form
    $Form.TopMost = $true
    $Form.StartPosition = "Manual"
    $Form.Size = '1,1'
    $Form.Location = '0,0'
    $Form.Show()
    $Form.Hide()

    $Result =  [System.Windows.Forms.MessageBox]::Show($Form, $Message, $Title, $Buttons, [System.Windows.Forms.MessageBoxIcon]::$Icon)

    $Form.Dispose()
    return $Result
}

# Wrapper for different log message types
function Write-Message {
    param (
        [string]$Message,
        [ValidateSet("INFO", "NOTICE", "WARN", "ERROR")] 
        [string]$Level = "INFO",
        [bool]$Console = $true,
        [bool]$Log = $true,
        [bool]$Dialogue = $false,
        [string]$DialogueTitle = "CAA Compliance Fix"
    )

    if ($Console) { Write-Host "[$Level] $Message" }
    if ($Log) { Write-Log -Level $Level -Message $Message }
    if ($Dialogue) {
        $icon = switch ($Level) {
            "INFO"   { "Information" }
            "NOTICE" { "Information" }
            "WARN"   { "Warning" }
            "ERROR"  { "Error" }
        }
        Show-MessageBox -Message $Message -Title $DialogueTitle -Icon $icon
    }
}

#Export-ModuleMember -Function Set-LogFilePath, Write-Log, Show-MessageBox, Write-Message
