#==============================================================#
#                  CAA-Launcher.ps1 (menu)                     #
#==============================================================#
$RepoURL = "https://raw.githubusercontent.com/HTTP-218/Endpoint_Verification/dev/CAA-Tool.ps1"
$PS5Path  = "C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe"

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
        $Command = "Invoke-RestMethod $RepoURL | .\CAA-Tool -ScanOnly"
        Start-Process $PS5Path -ArgumentList "-NoExit", "-ExecutionPolicy", "Bypass", "-Command", $Command -WindowStyle Normal
        return
    }
    "2" {
        Write-Host "[INFO] Launching Full Tool (requires elevation)..." -ForegroundColor Yellow
        try {
            $Command = "Invoke-RestMethod $RepoURL | Invoke-Expression"
            Start-Process $PS5Path -Verb RunAs -ArgumentList "-NoExit", "-ExecutionPolicy", "Bypass", "-Command", $Command -WindowStyle Normal
        }
        catch {
            Write-Host "[ERROR] Could not launch elevated PowerShell. UAC prompt was likely cancelled." -ForegroundColor Red
            Read-Host "Press any key to exit"
            exit 1
        }
    }
    "0" {
        Write-Host "Bye!"
        exit 0
    }
    default {
        Write-Host "[ERROR] Invalid selection. Please run the script again." -ForegroundColor Red
        Read-Host "Press any key to exit"
        exit 1
    }
}
