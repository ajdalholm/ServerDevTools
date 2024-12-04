#Requires -Version 5
<# Notes:

    Goal - Create a domain controller and populate with OUs, Groups, and Users.
    This script must be run after prepDomainController.

    Disclaimer - This example code is provided without copyright and AS IS.  It is free for you to use and modify.

#>
function Split-File ([string]$inFile, [int]$bufSize = 5mb) {
    $stream = [System.IO.File]::OpenRead($inFile)
    $chunkNum = 1
    $barr = New-Object byte[] $bufSize

    $fileinfo = [System.IO.FileInfo]$inFile
    $name = $fileinfo.Name
    $dir = $fileinfo.Directory

    while ($bytesRead = $stream.Read($barr, 0, $bufsize)) {
        $outFile = Join-Path $dir "$name.part$chunkNum"
        $ostream = [System.IO.File]::OpenWrite($outFile)
        $ostream.Write($barr, 0, $bytesRead)
        $ostream.Close()
        Write-Host "Wrote $outFile"
        $chunkNum += 1
    }
    $stream.Close()
}
function Join-File ([string]$infilePrefix,[string]$outFilePath) {
    $fileinfo = [System.IO.FileInfo]$infilePrefix
    #$outFile = Join-Path $fileinfo.Directory $fileinfo.BaseName
    $outFile = Get-Item -Path $outFilePath
    $ostream = [System.Io.File]::OpenWrite($outFile)
    $chunkNum = 1
    $infileName = "$infilePrefix$chunkNum"

    while (Test-Path $infileName) {
        $bytes = [System.IO.File]::ReadAllBytes($infileName)
        $ostream.Write($bytes, 0, $bytes.Count)
        Write-Host "Read $infileName"
        $chunkNum += 1
        $infileName = "$infilePrefix$chunkNum"
    }

    $ostream.close()
}

$Binaries = @(
    'https://github.com/ajdalholm/ServerDevToolsBinaries/blob/9f0c1eff9635452930b7da4c1d7ca56ca8598021/76fba573f02545629706ab99170237bc_License1.xml?raw=true',
    'https://github.com/ajdalholm/ServerDevToolsBinaries/blob/9f0c1eff9635452930b7da4c1d7ca56ca8598021/Microsoft.DesktopAppInstaller_8wekyb3d8bbwe.msixbundle.part1?raw=true',
    'https://github.com/ajdalholm/ServerDevToolsBinaries/blob/9f0c1eff9635452930b7da4c1d7ca56ca8598021/Microsoft.DesktopAppInstaller_8wekyb3d8bbwe.msixbundle.part2?raw=true',
    'https://github.com/ajdalholm/ServerDevToolsBinaries/blob/9f0c1eff9635452930b7da4c1d7ca56ca8598021/Microsoft.DesktopAppInstaller_8wekyb3d8bbwe.msixbundle.part3?raw=true',
    'https://github.com/ajdalholm/ServerDevToolsBinaries/blob/9f0c1eff9635452930b7da4c1d7ca56ca8598021/Microsoft.DesktopAppInstaller_8wekyb3d8bbwe.msixbundle.part4?raw=true',
    'https://github.com/ajdalholm/ServerDevToolsBinaries/blob/9f0c1eff9635452930b7da4c1d7ca56ca8598021/Microsoft.DesktopAppInstaller_8wekyb3d8bbwe.msixbundle.part5?raw=true',
    'https://github.com/ajdalholm/ServerDevToolsBinaries/blob/9f0c1eff9635452930b7da4c1d7ca56ca8598021/Microsoft.DesktopAppInstaller_8wekyb3d8bbwe.msixbundle.part6?raw=true',
    'https://github.com/ajdalholm/ServerDevToolsBinaries/blob/9f0c1eff9635452930b7da4c1d7ca56ca8598021/Microsoft.UI.Xaml.2.8.appx?raw=true',
    'https://github.com/ajdalholm/ServerDevToolsBinaries/blob/9f0c1eff9635452930b7da4c1d7ca56ca8598021/Microsoft.VCLibs.x64.14.00.Desktop.appx?raw=true'
)

do {
    $guid = [system.guid]::NewGuid().ToString()
 } while (Test-Path -Path (Join-Path -Path $env:TEMP -ChildPath $guid) -PathType Container )
$Tempfolder = New-Item -Path $env:TEMP -Name $guid -ItemType Directory

$Binaries | ForEach-Object {
    $url = $_
    $filename = $url.Split('/')[-1].Split('?')[0]
    $outFile = Join-Path -Path $Tempfolder.FullName -ChildPath $filename
    Invoke-WebRequest -Uri $url -OutFile $outFile
}

Push-Location -Path $Tempfolder.FullName -ErrorAction SilentlyContinue
Add-AppxPackage -Path .\Microsoft.UI.Xaml.2.8.appx
Add-AppxPackage -Path .\Microsoft.VCLibs.x64.14.00.Desktop.appx
#Join winget package from parts
$firstPartOfFile = Get-Item -path .\Microsoft.DesktopAppInstaller_8wekyb3d8bbwe.msixbundle.part1
$tempFile = $firstPartOfFile.FullName.Split('.part')[0]
Join-File -infilePrefix $firstPartOfFile.FullName.Substring(0,$firstPartOfFile.FullName.Length-1) -outFilePath $tempFile
Start-Sleep -Seconds 3
Add-AppxProvisionedPackage -Online -PackagePath $tempFile -LicensePath .\76fba573f02545629706ab99170237bc_License1.xml
Pop-Location

Start-Sleep -Seconds 5

winget install Git.Git 7zip.7zip Google.Chrome Microsoft.VisualStudioCode Microsoft.PowerShell WinMerge.WinMerge Microsoft.WindowsTerminal --accept-source-agreements --accept-package-agreements --scope machine

#Refresh Path
Invoke-Command -ScriptBlock {$env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User") }

#clone this repository
Invoke-Command -ScriptBlock {powershell.exe -Command "& {Push-Location $env:USERPROFILE ; & 'git.exe' clone https://github.com/ajdalholm/ServerDevTools.git; Pop-Location}"}
