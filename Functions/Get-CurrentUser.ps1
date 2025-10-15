function Get-CurrentUser {
    param (
        [ValidateSet("Auto", "Home", "Pro")]
        [string]$Mode = "Auto"
    )

    if ($Mode -eq "Auto") {
        $Edition = (Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion").EditionID
        $Mode = if ($Edition -eq "Core") { "Home" } else { "Pro" }
    }

    try {
        switch ($Mode) {
            "Home" {
                ((Get-CimInstance Win32_ComputerSystem).UserName).Split('\')[-1]
            }
            "Pro" {
                $SessionLine = (quser 2>$null | Where-Object { $_ -match ">" })
                if ($SessionLine) {
                    # Remove leading '>' and extra spaces
                    $SessionLine = $SessionLine -replace '^>\s*', ''
                    $Columns = $SessionLine -replace '\s{2,}', ',' -split ','
                    
                    return $columns[0]
                }
            }
        }
    }
    catch {
        Write-Warning "Failed to get current user: $($_.Exception.Message)"
        return $null
    }
}