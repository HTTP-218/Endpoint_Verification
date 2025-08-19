######################################################################################################
#                                                                                                    #
#                                       CAA-ComplianceScan.ps1                                       #
#                                                                                                    #
######################################################################################################

#====================================================================================================#
#                                           [ Functions ]                                            #
#====================================================================================================#
#region Functions
function Write-Log {
    param (
        [Parameter(Mandatory = $true)]
        [string]$Level,    
        [string]$Message
    )
    $Timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    $LogEntry = "$Timestamp - [$Level] $Message"
    $LogEntry | Out-File -FilePath $LogFilePath -Append -Encoding Unicode
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
        [string]$DialogueTitle = "CAA Compliance Scan"
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

function Get-LoggedInUser {
    $SessionLine = (quser 2>$null | Where-Object { $_ -match ">" })
    if ($SessionLine) {
        # Remove leading '>' and extra spaces
        $SessionLine = $SessionLine -replace '^>\s*', ''       
        $Columns = $SessionLine -replace '\s{2,}', ',' -split ','

        return $columns[0]
    }
    return $null
}

#endregion

#====================================================================================================#
#                                           [ Variables ]                                            #
#====================================================================================================#
$ErrorActionPreference = "Stop"
$ProgressPreference = 'SilentlyContinue'
$LogFilePath = "C:\Windows\Temp\CAA-ComplianceScan.log"
$Summary = @()

Add-Type -AssemblyName System.Windows.Forms

Set-Content -Path $LogFilePath -Encoding Unicode -Value "
##########################################################################
#                                                                        #
#                         CAA-ComplianceScan.ps1                         #
#                                                                        #
##########################################################################
"

#====================================================================================================#
#                                        [ Load JSON Config ]                                        #
#====================================================================================================#
$JSONPath = "C:\Windows\Temp\caa.json"

try {
    Invoke-WebRequest -Uri "https://raw.githubusercontent.com/2mmkolibri/Endpoint_Verification/dev/caa.json" -OutFile $JSONPath
    $Variables = Get-Content -Raw -Path $JSONPath | ConvertFrom-Json
}
catch {
    Write-Message -Message "Failed to initialise JSON config file`n`n$($_.Exception.Message)" -Level "ERROR" -Dialogue $true
    exit 1
}

#====================================================================================================#
#                                      [ Windows Build Check ]                                       #
#====================================================================================================#
Write-Message -Message "========== Starting Windows Build Check ==========" -Level "INFO"

$WinRegKey = Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion" -ErrorAction SilentlyContinue
$WindowsBuild = $WinRegKey.CurrentBuildNumber
$DisplayVersion = $WinRegKey.DisplayVersion

if (!$WindowsBuild) {
    Write-Message -Message "Unable to determine Windows build number. You can check this manually with the winver command" -Level "WARN"
    $Summary += "Unable to check Windows build number"
}
else {
    $MatchingRequirement = $Variables.BuildRequirements |
    Where-Object { $WindowsBuild -ge $_.MinBuild -and ($_.MaxBuild -eq $null -or $WindowsBuild -le $_.MaxBuild) } |
    Sort-Object MinBuild -Descending |
    Select-Object -First 1

    if ($null -eq $MatchingRequirement) {
        Write-Message -Message "Windows build $($DisplayVersion) is not compliant" -Level "WARN"
        $Summary += "Windows build $($DisplayVersion) is not supported"
    } 
    else {
        Write-Message -Message "Windows is compliant with $($MatchingRequirement.Label) (Build $WindowsBuild)" -Level "INFO"
    }
}

#====================================================================================================#
#                                          [ Chrome Check ]                                          #
#====================================================================================================#
Write-Message -Message "========== Chrome Check ========== " -Level "INFO"

$Chrome = Get-Package | Where-Object { $_.Name -like "*Google Chrome*" }

if ($null -eq $Chrome) {
    Write-Message -Message "Google Chrome is not installed on this device" -Level "WARN"
    $Summary += "Chrome is not installed"
}
else {
    Write-Message -Message "Google Chrome is already installed. Checking version..." -Level "INFO"
    if ($Chrome.Version -lt $Variables.ChromeVersion) {
        Write-Message -Message "Chrome is not compliant" -Level "WARN"
        $Summary += "Chrome version $($Chrome.Version) is below the minimum requirement"
    }   
    else {
        Write-Message -Message "Chrome is compliant with version $($Chrome.Version)" -Level "INFO"
    }
}

#====================================================================================================#
#                             [ Endpoint Verification Extension Check ]                              #
#====================================================================================================#
Write-Message -Message "========== Endpoint Verification Extension Check ==========" -Level "INFO"

$Chrome = Get-Package -ErrorAction SilentlyContinue | Where-Object { $_.Name -like "*Google Chrome*" }
$Username = Get-LoggedInUser

if ($Chrome) {
    $ChromeProfiles = Get-ChildItem -Path "C:\Users\$Username\AppData\Local\Google\Chrome\User Data" -Directory | Where-Object { $_.Name -eq "Default" -or $_.Name -match "^Profile \d+$" }
    $EVExtension = @()

    foreach ($ChromeProfile in $ChromeProfiles) {
        $ExtensionsFolderPath = Join-Path $ChromeProfile.FullName "Extensions"
        $ExtensionPath = Join-Path $ExtensionsFolderPath $Variables.ExtensionID
        
        if (Test-Path $ExtensionPath) {
            $EVExtension += $ExtensionPath
        }
    }

    if ($EVExtension) {
        Write-Message -Message "Endpoint Verification extension is installed in one or more profiles" -Level "INFO"
    }
    else {
        Write-Message -Message  "Endpoint Verification extension could not be found in any Chrome profile" -Level "WARN"
        $Summary += "Endpoint Verification extension is not installed"
    }
}
else {
    Write-Message -Message  "Chrome is not installed. Skipping Endpoint Verification extension check" -Level "WARN"
    $Summary += "Endpoint Verification extension is not installed"
}

#====================================================================================================#
#                                     [ Firewall Status Check ]                                      #
#====================================================================================================#
Write-Message -Message "========== Firewall Status Check ==========" -Level "INFO"

$FirewallStatus = Get-NetFirewallProfile | Select-Object Name, Enabled

foreach ($NetProfile in $FirewallStatus) {
    if ($NetProfile.Enabled -eq $false) {
       Write-Message -Message "The $($NetProfile.Name) firewall profile is disabled" -Level "WARN"
       $Summary += "$($NetProfile.Name) firewall profile."
    }
    else {
        Write-Message -Message "Firewall $($NetProfile.Name) profile is enabled" -Level "INFO"
    }
}

#====================================================================================================#
#                               [ Endpoint Verification Helper Check ]                               #
#====================================================================================================#
Write-Message -Message "========== Endpoint Verification Helper Check ==========" -Level "INFO"

$EVHelperApp = Get-Package | Where-Object { $_.Name -like "*Google Endpoint Verification*" }

if ($null -eq $EVHelperApp) {
    Write-Message -Message "Endpoint Verification Helper is not installed" -Level "WARN"
    $Summary += "Endpoint Verification Helper is not installed"
}
else {
    Write-Message -Message  "Endpoint Verification Helper is installed" -Level "INFO"
}

#====================================================================================================#
#                                             [ Cleanup ]                                            #
#====================================================================================================#
Write-Message -Message "========== Clean Up ==========" -Level "INFO"

Write-Message -Message  "Deleting JSON file..." -Level "INFO"
try {
    Remove-Item $JSONPath -Force
    Write-Message -Message  "JSON file deleted" -Level "NOTICE"     
}
catch {
    Write-Message -Message  "Failed to delete JSON file: $($_.Exception.Message)" -Level "WARN"
}

#====================================================================================================#
#                                       [ Compliance Summary ]                                       #
#====================================================================================================#
Write-Message -Message  "========== Summary ==========" -Level "INFO"
Write-Message -Message  "Generating summary report..." -Level "INFO"

if ($Summary.Count -eq 0) {
    $Message = @"
    All checks passed. Your device is compliant.

    If you're still unable to access Gmail, try the following:

      1. Open Google Chrome and wait 2 minutes
      2. Open the Endpoint Verification extension
      3. Click 'SYNC NOW'
      4. Reload your Gmail tab
"@
    Write-Message -Message $Message -Level "INFO" -Console $false -Log $false -Dialogue $true
} 
else {
    $SummaryText = ($Summary | ForEach-Object { "    - $_" }) -join "`n"
    $Message = @"
    Your device is not compliant:

$SummaryText

Please address each issue, then run the Endpoint Verification sync to regain access.
"@
    Write-Message -Message $Message -Level "ERROR" -Console $false -Log $false -Dialogue $true
}

exit 0
