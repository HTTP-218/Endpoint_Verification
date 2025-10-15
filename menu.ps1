#==============================================================#
#                  CAA-Launcher.ps1 (menu)                     #
#==============================================================#
$RepoURL = "https://http-218.github.io/CAA-Tool.ps1"

Write-Host ""
Write-Host "##############################################################" -ForegroundColor Cyan
Write-Host "#                          HTTP 218                          #" -ForegroundColor Cyan
Write-Host "#                        CAA-Tool.ps1                        #" -ForegroundColor Cyan
Write-Host "##############################################################" -ForegroundColor Cyan   
Write-Host ""
Write-Host "[1] Scan Only (No admin required)" -ForegroundColor Green
Write-Host "[2] Full Tool (Requires admin privileges)" -ForegroundColor Yellow
Write-Host "[0] Exit"
Write-Host ""
$Choice = Read-Host "Enter a number"
Write-Host ""

switch ($Choice) {
    "1" {
        Write-Host "[INFO] Launching Scan Only mode..." -ForegroundColor Green
        $Command = Invoke-Expression "& { $(Invoke-RestMethod $RepoURL) } -ScanOnly"
        Start-Process powershell -ArgumentList "-NoExit -ExecutionPolicy Bypass -Command $Command" -WindowStyle Normal
        return
    }
    "2" {
        Write-Host "[INFO] Launching Full Tool (requires elevation)..." -ForegroundColor Yellow
        try {
            Start-Process powershell -Verb RunAs -ArgumentList "Invoke-RestMethod $RepoURL | Invoke-Expression" -WindowStyle Normal
        }
        catch {
            Write-Host "[ERROR] Could not launch elevated PowerShell. UAC prompt was likely cancelled." -ForegroundColor Red
            Read-Host "Press Enter to exit..."
            exit 1
        }
    }
    "0" {
        Write-Host "Bye!"
        exit 0
    }
    default {
        Write-Host "[ERROR] Invalid selection. Please run the script again." -ForegroundColor Red
        Read-Host "Press Enter to exit..."
        exit 1
    }
}
