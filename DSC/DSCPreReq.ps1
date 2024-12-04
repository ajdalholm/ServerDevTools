$DSCModules = @('ActiveDirectoryDSC', 'ComputerManagementDSC', 'NetworkingDSC', 'DnsServerDSC','xRemoteDesktopAdmin','PSDesiredStateConfiguration')
$DSCModules| ForEach-Object {
  if ( -not (Get-Module -ListAvailable -Name $_) ) {
    Install-Module -Name $_ -Scope CurrentUser
  }
}

$PreReqTestStatus = $true
$DSCModules| ForEach-Object {
    $PreReqTestStatus = $PreReqTestStatus -and (Get-Module -ListAvailable -Name $_)
}

Write-Information -MessageData "PreReq Status: $PreReqTestStatus" -InformationAction Continue
