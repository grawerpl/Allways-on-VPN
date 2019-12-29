<#
.SYNOPSIS
    Creates an Always On VPN user tunnel connection.

.PARAMETER xmlFilePath
    Path to the ProfileXML configuration file.

.PARAMETER ProfileName
    Name of the VPN profile to be created.

.EXAMPLE
    .\New-AovpnConnection.ps1 -xmlFilePath 'C:\Users\rdeckard\desktop\ProfileXML.xml' -ProfileName 'Always On VPN User Tunnel'

.DESCRIPTION
    This script will create an Always On VPN user tunnel on supported Windows 10 devices. 

.LINK
    https://docs.microsoft.com/en-us/windows-server/remote/remote-access/vpn/always-on-vpn/deploy/vpn-deploy-client-vpn-connections#bkmk_fullscript

.NOTES
    Version:            1.01
    Creation Date:      May 28, 2019
    Last Updated:       May 29, 2019
    Special Note:       This script adapted from published guidance provided by Microsoft.
    Original Author:    Microsoft Corporation
    Original Script:    https://docs.microsoft.com/en-us/windows-server/remote/remote-access/vpn/always-on-vpn/deploy/vpn-deploy-client-vpn-connections#bkmk_fullscript
    Author:             Richard Hicks
    Organization:       Richard M. Hicks Consulting, Inc.
    Contact:            rich@richardhicks.com
    Web Site:           www.richardhicks.com

#>

[CmdletBinding()]

Param(

    [Parameter(Mandatory = $True, HelpMessage = 'Enter the path to the ProfileXML file.')]    
    [string]$xmlFilePath,
    [Parameter(Mandatory = $True, HelpMessage = 'Enter a name for the VPN profile.')]        
    [string]$ProfileName

)

# Import ProfileXML
$ProfileXML = Get-Content $xmlFilePath

# Escape spaces in profile name
$ProfileNameEscaped = $ProfileName -replace ' ', '%20'
$ProfileXML = $ProfileXML -replace '<', '&lt;'
$ProfileXML = $ProfileXML -replace '>', '&gt;'
$ProfileXML = $ProfileXML -replace '"', '&quot;'

# OMA URI information
$NodeCSPURI = './Vendor/MSFT/VPNv2'
$NamespaceName = 'root\cimv2\mdm\dmmap'
$ClassName = 'MDM_VPNv2_01'

try {

    $Username = Get-WmiObject -Class Win32_ComputerSystem | Select-Object username
    $User = New-Object System.Security.Principal.NTAccount($Username.Username)
    $Sid = $User.Translate([System.Security.Principal.SecurityIdentifier])
    $SidValue = $Sid.Value
    Write-Verbose "User SID is $SidValue."

}

catch [Exception] {

    Write-Output "Unable to get user SID. User may be logged on over Remote Desktop: $_"
    Exit

}

$Session = New-CimSession
$Options = New-Object Microsoft.Management.Infrastructure.Options.CimOperationOptions
$Options.SetCustomOption('PolicyPlatformContext_PrincipalContext_Type', 'PolicyPlatform_UserContext', $false)
$Options.SetCustomOption('PolicyPlatformContext_PrincipalContext_Id', "$SidValue", $false)

try {

    $NewInstance = New-Object Microsoft.Management.Infrastructure.CimInstance $className, $namespaceName
    $Property = [Microsoft.Management.Infrastructure.CimProperty]::Create('ParentID', "$nodeCSPURI", 'String', 'Key')
    $NewInstance.CimInstanceProperties.Add($Property)
    $Property = [Microsoft.Management.Infrastructure.CimProperty]::Create('InstanceID', "$ProfileNameEscaped", 'String', 'Key')
    $NewInstance.CimInstanceProperties.Add($Property)
    $Property = [Microsoft.Management.Infrastructure.CimProperty]::Create('ProfileXML', "$ProfileXML", 'String', 'Property')
    $NewInstance.CimInstanceProperties.Add($Property)
    $Session.CreateInstance($namespaceName, $NewInstance, $Options)
    Write-Output "Created $ProfileName profile."

}

catch [Exception] {

    Write-Output "Unable to create $ProfileName profile: $_"
    Exit

}

Write-Output 'Script complete.'
