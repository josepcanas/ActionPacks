﻿#Requires -Version 4.0
#Requires -Modules ActiveDirectory

<#
    .SYNOPSIS
         Sets the properties of the Active Directory group.
         Only parameters with value are set
    
    .DESCRIPTION  

    .NOTES
        This PowerShell script was developed and optimized for ScriptRunner. The use of the scripts requires ScriptRunner. 
        The customer or user is authorized to copy the script from the repository and use them in ScriptRunner. 
        The terms of use for ScriptRunner do not apply to this script. In particular, AppSphere AG assumes no liability for the function, 
        the use and the consequences of the use of this freely available script.
        PowerShell is a product of Microsoft Corporation. ScriptRunner is a product of AppSphere AG.
        © AppSphere AG

    .COMPONENT
        Requires Module ActiveDirectory

    .LINK
        https://github.com/scriptrunner/ActionPacks/tree/master/ActiveDirectory/Groups

    .Parameter OUPath
        Specifies the AD path

    .Parameter GroupName
        DistinguishedName or SamAccountName of the Active Directory group

    .Parameter DomainAccount
        Active Directory Credential for remote execution on jumphost without CredSSP

    .Parameter Description
        Specifies a description of the group

    .Parameter Scope
        Specifies the group scope of the group

    .Parameter Category
        Specifies the category of the group

    .Parameter DomainName
        Name of Active Directory Domain
        
    .Parameter SearchScope
        Specifies the scope of an Active Directory search

    .Parameter AuthType
        Specifies the authentication method to use
#>

param(
    [Parameter(Mandatory = $true,ParameterSetName = "Local or Remote DC")]
    [Parameter(Mandatory = $true,ParameterSetName = "Remote Jumphost")]
    [string]$OUPath,  
    [Parameter(Mandatory = $true,ParameterSetName = "Local or Remote DC")]
    [Parameter(Mandatory = $true,ParameterSetName = "Remote Jumphost")]
    [string]$GroupName,
    [Parameter(Mandatory = $true,ParameterSetName = "Remote Jumphost")]
    [PSCredential]$DomainAccount,
    [Parameter(ParameterSetName = "Local or Remote DC")]
    [Parameter(ParameterSetName = "Remote Jumphost")]
    [string]$Description,
    [Parameter(ParameterSetName = "Local or Remote DC")]
    [Parameter(ParameterSetName = "Remote Jumphost")]
    [ValidateSet('','DomainLocal', 'Global', 'Universal')]
    [string]$Scope = '',
    [Parameter(ParameterSetName = "Local or Remote DC")]
    [Parameter(ParameterSetName = "Remote Jumphost")]
    [ValidateSet('','Distribution', 'Security')]
    [string]$Category = '',  
    [Parameter(ParameterSetName = "Local or Remote DC")]
    [Parameter(ParameterSetName = "Remote Jumphost")]
    [string]$DomainName,
    [Parameter(ParameterSetName = "Local or Remote DC")]
    [Parameter(ParameterSetName = "Remote Jumphost")]
    [ValidateSet('Base','OneLevel','SubTree')]
    [string]$SearchScope='SubTree',
    [Parameter(ParameterSetName = "Local or Remote DC")]
    [Parameter(ParameterSetName = "Remote Jumphost")]
    [ValidateSet('Basic', 'Negotiate')]
    [string]$AuthType="Negotiate"
)

Import-Module ActiveDirectory

try{
    $Script:Grp
    [hashtable]$cmdArgs = @{'ErrorAction' = 'Stop'
                            'AuthType' = $AuthType
                            }
    if($null -ne $DomainAccount){
        $cmdArgs.Add("Credential", $DomainAccount)
    }
    if([System.String]::IsNullOrWhiteSpace($DomainName)){
        $cmdArgs.Add("Current", 'LocalComputer')
    }
    else {
        $cmdArgs.Add("Identity", $DomainName)
    }
    $Domain = Get-ADDomain @cmdArgs

    $cmdArgs = @{'ErrorAction' = 'Stop'
                'Server' = $Domain.PDCEmulator
                'AuthType' = $AuthType
                'Filter' = {(SamAccountName -eq $GroupName) -or (DistinguishedName -eq $GroupName)} 
                'SearchBase' = $OUPath 
                'SearchScope' = $SearchScope
                }
    if($null -ne $DomainAccount){
        $cmdArgs.Add("Credential", $DomainAccount)
    }

    $Script:Grp = Get-ADGroup @cmdArgs
    if($null -ne $Script:Grp){
        if(-not [System.String]::IsNullOrWhiteSpace($Description)){
            $Script:Grp.Description = $Description
        }
        if(-not [System.String]::IsNullOrWhiteSpace($DisplayName)){
            $Script:Grp.DisplayName = $DisplayName
        }
        if(-not [System.String]::IsNullOrWhiteSpace($HomePage)){
            $Script:Grp.HomePage = $HomePage
        }
        if(-not [System.String]::IsNullOrWhiteSpace($Scope)){
            $Script:Grp.GroupScope = $Scope
        }
        if(-not [System.String]::IsNullOrWhiteSpace($Category)){
            $Script:Grp.GroupCategory = $Category
        }
        $cmdArgs = @{'ErrorAction' = 'Stop'
                    'Server' = $Domain.PDCEmulator
                    'AuthType' = $AuthType
                    'Instance' =$Script:Grp
                    }
        if($null -ne $DomainAccount){
            $cmdArgs.Add("Credential", $DomainAccount)
        }
        Set-ADGroup @cmdArgs
        
        if($SRXEnv) {
            $SRXEnv.ResultMessage = "Group $($GroupName) changed"
        } 
        else{
            Write-Output "Group $($GroupName) changed"
        }
    }
    else {
        if($SRXEnv) {
            $SRXEnv.ResultMessage = "Group $($GroupName) not found"
        }    
    Throw "Group $($GroupName) not found"
    }   
}
catch{
    throw
}
finally{
}