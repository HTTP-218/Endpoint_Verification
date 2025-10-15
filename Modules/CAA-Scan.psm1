function Get-WindowsBuild {
    param(
        [Parameter(Mandatory = $true)]
        [array]$BuildRequirements
    )

    Write-Message -Message "========== Starting Windows Build Check ==========" -Level "INFO"

    $WinRegKey = Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion" -ErrorAction SilentlyContinue
    $WindowsBuild = $WinRegKey.CurrentBuildNumber
    $DisplayVersion = $WinRegKey.DisplayVersion

    if (!$WinRegKey) {
        Write-Message -Message "Unable to determine Windows build number. You can check this manually with the winver command" -Level "WARN"
        return @{
            IsCompliant = $false
            Message = "Unable to check Windows build number"
        }
    }
    else {
        $MatchingRequirement = $BuildRequirements |
        Where-Object { $WindowsBuild -ge $_.MinBuild -and ($null -eq $_.MaxBuild -or $WindowsBuild -le $_.MaxBuild) } |
        Sort-Object MinBuild -Descending |
        Select-Object -First 1

        if ($null -eq $MatchingRequirement) {
            Write-Message -Message "Windows build $($DisplayVersion) is not compliant" -Level "WARN"
            return @{
                IsCompliant = $false
                Message = "Windows build $($DisplayVersion) is not supported"
        }
        } 
        else {
            Write-Message -Message "Windows is compliant with $($MatchingRequirement.Label) (Build $WindowsBuild)" -Level "INFO"
            return @{
                IsCompliant = $true
                Message     = $null
            }
        }
    }
}


function Get-ChromeStatus {
    param(
        [Parameter(Mandatory = $true)]
        [string]$ChromeVersion
    )

    Write-Message -Message "========== Chrome Check ========== " -Level "INFO"

    $Chrome = Get-Package -ErrorAction SilentlyContinue | Where-Object { $_.Name -like "*Google Chrome*" }

    if ($null -eq $Chrome) {
        Write-Message -Message "Google Chrome is not installed on this device" -Level "WARN"
        return @{
            IsCompliant = $false
            Message = "Chrome is not installed"
        }
    }
    else {
        Write-Message -Message "Google Chrome is already installed. Checking version..." -Level "INFO"
        if ($Chrome.Version -lt $ChromeVersion) {
            Write-Message -Message "Chrome is not compliant" -Level "WARN"
            return @{
                IsCompliant = $false
                Message = "Chrome version $($Chrome.Version) is below the minimum requirement"
            }
        }   
        else {
            Write-Message -Message "Chrome is compliant with version $($Chrome.Version)" -Level "INFO"
            return @{
                IsCompliant = $true
                Message     = $null
            }        
        }
    }
}

function Get-EVExtensionStatus {
    param(
        [Parameter(Mandatory = $true)]
        [string]$ExtensionID,
        [string]$Username
    )

    Write-Message -Message "========== Endpoint Verification Extension Check ==========" -Level "INFO"

    $Chrome = Get-Package -ErrorAction SilentlyContinue | Where-Object { $_.Name -like "*Google Chrome*" }

    if ($Chrome) {
        $ChromeProfiles = Get-ChildItem -Path "C:\Users\$Username\AppData\Local\Google\Chrome\User Data" -Directory | Where-Object { $_.Name -eq "Default" -or $_.Name -match "^Profile \d+$" }
        $EVExtension = @()

        foreach ($ChromeProfile in $ChromeProfiles) {
            $ExtensionsFolderPath = Join-Path $ChromeProfile.FullName "Extensions"
            $ExtensionPath = Join-Path $ExtensionsFolderPath $ExtensionID
        
            if (Test-Path $ExtensionPath) {
                $EVExtension += $ExtensionPath
            }
        }

        if ($EVExtension) {
            Write-Message -Message "Endpoint Verification extension is installed in one or more profiles" -Level "INFO"
            return @{
                IsCompliant = $true
                Message     = $null
            }
        }
        else {
            Write-Message -Message  "Endpoint Verification extension could not be found in any Chrome profile" -Level "WARN"
            return @{
                IsCompliant = $false
                Message = "Endpoint Verification extension is not installed"
            }
        }
    }
    else {
        Write-Message -Message  "Chrome is not installed. Skipping Endpoint Verification extension check" -Level "WARN"
        return @{
            IsCompliant = $false
            Message = "Endpoint Verification extension is not installed (Chrome missing)"
        }
    }
}

function Get-FirewallStatus {
    Write-Message -Message "========== Firewall Status Check ==========" -Level "INFO"

    $FirewallStatus = Get-NetFirewallProfile | Select-Object Name, Enabled
    $DisabledProfiles = @()
    $Messages = @()

    foreach ($NetProfile in $FirewallStatus) {
        if (-not $NetProfile.Enabled) {
            Write-Message -Message "Firewall $($NetProfile.Name) profile is disabled" -Level "WARN"
            $DisabledProfiles += $NetProfile.Name
            $Messages += "$($NetProfile.Name) firewall profile is disabled"
        }
        else {
            Write-Message -Message "Firewall $($NetProfile.Name) profile is enabled" -Level "INFO"
        }
    }

    return @{
        IsCompliant = ($DisabledProfiles.Count -eq 0)
        DisabledProfiles = $DisabledProfiles
        Message = $Messages
    }
}


function Get-EVHelperStatus {

    Write-Message -Message "========== Endpoint Verification Helper Check ==========" -Level "INFO"

    $EVHelperApp = Get-Package | Where-Object { $_.Name -like "*Google Endpoint Verification*" }

    if ($null -eq $EVHelperApp) {
        Write-Message -Message "Endpoint Verification Helper is not installed" -Level "WARN"
        return @{
            IsCompliant = $false
            Message = "Endpoint Verification Helper is not installed"
        }
    }
    else {
        Write-Message -Message  "Endpoint Verification Helper is installed" -Level "INFO"
        return @{
            IsCompliant = $true
            Message     = $null
        }
    }
}