Push-Location -Path $PSScriptRoot
$domainDNSNamespace = 'firefly.local'
$DomainDN = ($domainDNSNamespace.split('.') | % { "dc=$_" }) -join ","
$domainCred = Get-Credential -UserName "Administrator@$domaindnsnamespace" -Message "Please enter a new password for Domain Administrator."

$ConfigData = @{
    AllNodes = @(
        @{
            Nodename = "localhost"
            ThisComputerName = "RDC01"
            DomainName = $domainDNSNamespace
            DomainDN = $DomainDN
            DCDatabasePath = "C:\NTDS"
            DCLogPath = "C:\NTDS"
            SysvolPath = "C:\Sysvol"
            PSDscAllowPlainTextPassword = $true
            PSDscAllowDomainUser = $true
        }
    )
}



configuration BuildDomainController
{
    Import-DscResource -ModuleName ActiveDirectoryDSC, ComputerManagementDSC, PSDesiredStateConfiguration
    Node localhost
    {

        LocalConfigurationManager {
            RefreshMode = 'Push'
            ConfigurationModeFrequencyMins = 15
            ActionAfterReboot = 'ContinueConfiguration'
            ConfigurationMode = 'ApplyOnly'
            RebootNodeIfNeeded = $true
        }

        User Administrator {
            Ensure = 'Present'
            UserName = 'Administrator'
            Password = $domainCred
        }

        Computer NewComputerName {
            Name = $node.ThisComputerName
            DependsOn = '[User]Administrator'
        }

        WindowsFeature ADDSInstall {
            Ensure = 'Present'
            Name = 'AD-Domain-Services'
            DependsOn = '[Computer]NewComputerName'
        }

        WindowsFeature ADDSToolsInstall {
            Ensure = 'Present'
            Name = 'RSAT-ADDS'
            IncludeAllSubFeature = $true
            DependsOn = '[Computer]NewComputerName'
        }

        ADDomain FirstRDC {
            DomainName = $node.DomainName
            Credential = $domainCred
            SafemodeAdministratorPassword = $domainCred
            ForestMode = 'Win2012'
            DomainMode = 'Win2012'
            DatabasePath = $node.DCDatabasePath

            LogPath = $node.DCLogPath
            SysvolPath = $node.SysvolPath 
            DependsOn = @('[WindowsFeature]ADDSInstall','[WindowsFeature]ADDSToolsInstall')
        }
    }
}

BuildDomainController -ConfigurationData $ConfigData

Set-DSCLocalConfigurationManager -Path .\BuildDomainController -Confirm
Start-DscConfiguration -Wait -Force -Path .\BuildDomainController -Verbose -Confirm
Pop-Location