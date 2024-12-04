Push-Location -Path $PSScriptRoot
$domainDNSNamespace = 'firefly.local'
$DomainDN = ($domainDNSNamespace.split('.') | % { "dc=$_" }) -join ','
$domainCred = Get-Credential -UserName "Administrator@$domaindnsnamespace" -Message 'Please enter a new password for Domain Administrator.'

$ConfigData = @{
  AllNodes = @(
    @{
      Nodename                    = 'localhost'
      ThisComputerName            = 'RDC02'
      DomainName                  = $domainDNSNamespace
      DomainDN                    = $DomainDN
      DCDatabasePath              = 'C:\NTDS'
      DCLogPath                   = 'C:\NTDS'
      SysvolPath                  = 'C:\Sysvol'
      PSDscAllowPlainTextPassword = $true
      PSDscAllowDomainUser        = $true
    }
  )
}



configuration RDC02
{
    Import-DscResource -ModuleName ActiveDirectoryDSC, ComputerManagementDSC, PSDesiredStateConfiguration
  Node localhost
  {
    LocalConfigurationManager {
      RefreshMode                    = 'Push'
      ConfigurationModeFrequencyMins = 15
      ActionAfterReboot              = 'ContinueConfiguration'
      ConfigurationMode              = 'ApplyOnly'
      RebootNodeIfNeeded             = $true
    }
    
    Computer NewComputerName {
      Name      = $node.ThisComputerName
    }
    
    WindowsFeature ADDSInstall {
      Ensure    = 'Present'
      Name      = 'AD-Domain-Services'
      DependsOn = '[Computer]NewComputerName'
    }

    WindowsFeature ADDSToolsInstall {
      Ensure               = 'Present'
      Name                 = 'RSAT-ADDS'
      IncludeAllSubFeature = $true
      DependsOn            = '[Computer]NewComputerName'
    }

    WaitForADDomain 'WaitForestAvailability' {
      DomainName = $domainDNSNamespace
      Credential = $Credential
      DependsOn  = @('[WindowsFeature]ADDSInstall', '[WindowsFeature]ADDSToolsInstall')
    }

    ADDomainController 'DomainController' {
      DomainName                    = $node.DomainName
      Credential                    = $domainCred
      SafemodeAdministratorPassword = $domainCred
      DatabasePath                  = $node.DCDatabasePath
      LogPath                       = $node.DCLogPath
      SysvolPath                    = $node.SysvolPath 
      DependsOn                     = @('[WaitForADDomain]WaitForestAvailability')
      IsGlobalCatalog               = $true
      InstallDns                    = $true
    }
  }
}

RDC02 -ConfigurationData $ConfigData

Set-DscLocalConfigurationManager -Path .\RDC02 -Confirm
Start-DscConfiguration -Wait -Force -Path .\RDC02 -Verbose -Confirm
Pop-Location