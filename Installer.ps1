#Requires -Version 5
<# Notes:

    Goal - Create a domain controller and populate with OUs, Groups, and Users.
    This script must be run after prepDomainController.

    Disclaimer - This example code is provided without copyright and AS IS.  It is free for you to use and modify.

#>
Push-Location -Path $PSScriptRoot -ErrorAction SilentlyContinue
$Null = New-Item -ItemType Directory -Path (Join-Path -Path $env:UserProfile -ChildPath 'Documents\PowerShell\Modules') -Force -ErrorAction SilentlyContinue

Add-AppxPackage -Path .\Microsoft.UI.Xaml.2.8.appx
Add-AppxPackage -Path .\Microsoft.VCLibs.x64.14.00.Desktop.appx

Add-AppxProvisionedPackage -Online -PackagePath .\Microsoft.DesktopAppInstaller_8wekyb3d8bbwe.msixbundle -LicensePath 76fba573f02545629706ab99170237bc_License1.xml
Pop-Location

Start-Sleep -Seconds 5

winget install Git.Git 7zip.7zip Google.Chrome Microsoft.VisualStudioCode Microsoft.PowerShell WinMerge.WinMerge --accept-source-agreements --accept-package-agreements

#Refresh Path
Invoke-Command -ScriptBlock {$env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User") }

