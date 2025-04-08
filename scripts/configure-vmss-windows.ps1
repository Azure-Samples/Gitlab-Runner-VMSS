# install.ps1
# Script to install Git on a Windows system

Write-Host "Starting Git installation..." -ForegroundColor Green

# Check if Git is already installed
if (Get-Command git -ErrorAction SilentlyContinue) {
    Write-Host "Git is already installed." -ForegroundColor Yellow
    git --version
    exit 0
}

# Download Git installer
$gitInstallerUrl = "https://github.com/git-for-windows/git/releases/latest/download/Git-2.41.0-64-bit.exe"
$installerPath = "$env:TEMP\GitInstaller.exe"

Write-Host "Downloading Git installer from $gitInstallerUrl..." -ForegroundColor Green
Invoke-WebRequest -Uri $gitInstallerUrl -OutFile $installerPath -UseBasicParsing

# Run the installer silently
Write-Host "Installing Git..." -ForegroundColor Green
Start-Process -FilePath $installerPath -ArgumentList "/VERYSILENT" -Wait

# Verify installation
if (Get-Command git -ErrorAction SilentlyContinue) {
    Write-Host "Git has been successfully installed!" -ForegroundColor Green
    git --version
} else {
    Write-Host "Git installation failed." -ForegroundColor Red
    exit 1
}

# Clean up installer
Remove-Item -Path $installerPath -Force
Write-Host "Installation complete and temporary files cleaned up." -ForegroundColor Green