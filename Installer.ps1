#Requires -Version 5
<# Notes:

    Goal - Create a domain controller and populate with OUs, Groups, and Users.
    This script must be run after prepDomainController.

    Disclaimer - This example code is provided without copyright and AS IS.  It is free for you to use and modify.

#>

Install-Script Winget-Install
Winget-Install

Push-Location -Path $Tempfolder.FullName -ErrorAction SilentlyContinue
Add-AppxPackage -Path .\Microsoft.UI.Xaml.2.8.appx
Add-AppxPackage -Path .\Microsoft.VCLibs.x64.14.00.Desktop.appx
#Join winget package from parts
$firstPartOfFile = Get-Item -path .\Microsoft.DesktopAppInstaller_8wekyb3d8bbwe.msixbundle.part1
$tempFile = $firstPartOfFile.Name.Substring(0,$firstPartOfFile.Name.LastIndexOf('.'))
New-Item -Path . -Name $tempFile -ItemType File
Join-File -infilePrefix $firstPartOfFile.FullName.Substring(0,$firstPartOfFile.FullName.Length-1) -outFilePath (Join-Path -Path $firstPartOfFile.Directory.FullName -ChildPath $tempFile)
Start-Sleep -Seconds 3
Add-AppxProvisionedPackage -Online -PackagePath $tempFile -LicensePath .\76fba573f02545629706ab99170237bc_License1.xml
Pop-Location

Start-Sleep -Seconds 5

winget install Git.Git 7zip.7zip Google.Chrome Microsoft.VisualStudioCode Microsoft.PowerShell WinMerge.WinMerge Microsoft.WindowsTerminal --accept-source-agreements --accept-package-agreements --scope machine

#Refresh Path
Invoke-Command -ScriptBlock {$env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User") }

#clone this repository
Invoke-Command -ScriptBlock {powershell.exe -Command "& {Push-Location $env:USERPROFILE ; & 'git.exe' clone https://github.com/ajdalholm/ServerDevTools.git; Pop-Location}"}
