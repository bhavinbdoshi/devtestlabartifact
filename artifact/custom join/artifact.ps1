[CmdletBinding()]
param
(
    [Parameter(Mandatory = $true)]
    [string] $DomainAdminUsername,

    [Parameter(Mandatory = $true)]
    [string] $DomainAdminPassword,

    [Parameter(Mandatory = $true)]
    [string] $DomainToJoin,

    [Parameter(Mandatory = $false)]
    [string] $OUPath,

    [Parameter(Mandatory = $false)]
    [string] $ADGroup
)

###################################################################################################
#
# PowerShell configurations
#

# NOTE: Because the $ErrorActionPreference is "Stop", this script will stop on first failure.
#       This is necessary to ensure we capture errors inside the try-catch-finally block.
$ErrorActionPreference = "Stop"

# Ensure we set the working directory to that of the script.
Push-Location $PSScriptRoot

###################################################################################################
#
# Handle all errors in this script.
#

trap
{
    # NOTE: This trap will handle all errors. There should be no need to use a catch below in this
    #       script, unless you want to ignore a specific error.
    $message = $error[0].Exception.Message
    if ($message)
    {
        Write-Host -Object "ERROR: $message" -ForegroundColor Red
    }
    
    # IMPORTANT NOTE: Throwing a terminating error (using $ErrorActionPreference = "Stop") still
    # returns exit code zero from the PowerShell script when using -File. The workaround is to
    # NOT use -File when calling this script and leverage the try-catch-finally block and return
    # a non-zero exit code from the catch block.
    Write-Host 'Artifact failed to apply.'
    exit -1
}

###################################################################################################
#
# Functions used in this script.
#

function Join-Domain 
{
    [CmdletBinding()]
    param
    (
        [string] $DomainName,
        [string] $UserName,
        [securestring] $Password,
        [string] $OUPath,
        [string] $ADGroup
    )

    if ((Get-WmiObject Win32_ComputerSystem).Domain -eq $DomainName)
    {
        Write-Host "Computer $($Env:COMPUTERNAME) is already joined to domain $DomainName."
    }
    else
    {

    # Main execution block.
    #
    #    $credential = New-Object System.Management.Automation.PSCredential($UserName, $Password)
    #    
    #    if ($OUPath)
    #    {
    #        [Microsoft.PowerShell.Commands.ComputerChangeInfo]$computerChangeInfo = Add-Computer -DomainName $DomainName -Credential $credential -OUPath $OUPath -Force -PassThru
    #    }
    #    else
    #    {
    #        [Microsoft.PowerShell.Commands.ComputerChangeInfo]$computerChangeInfo = Add-Computer -DomainName $DomainName -Credential $credential -Force -PassThru
    #    }
    #    
    #    if (-not $computerChangeInfo.HasSucceeded)
    #    {
    #        throw "Failed to join computer $($Env:COMPUTERNAME) to domain $DomainName."
    #    }
        

        $x = Get-WindowsCapability -Name 'Rsat.ActiveDirectory.DS-LDS.Tools~~~~0.0.1.0' -Online
        
        Write-Host "Status of Rsat.ActiveDirectory.DS-LDS.Tools~~~~0.0.1.0 Package on VM and status"
        Write-Host $x[0].Name
        Write-Host $x[0].State

        Write-Host "Running Get-Command Module ActiveDirectory"
        Get-Command -Module ActiveDirectory
        Write-Host "Completed running Get-Command Module ActiveDirectory"

    #    $cnt = Get-Command Module ActiveDirectory | measure-object | select count
    #    Write-Host "Count of ActiveDirectory Module Before Installation"
    #    Write-Host $cnt


        Add-WindowsCapability -online -Name "Rsat.ActiveDirectory.DS-LDS.Tools~~~~0.0.1.0"

        $x2 = Get-WindowsCapability -Name 'Rsat.ActiveDirectory.DS-LDS.Tools~~~~0.0.1.0' -Online
        
        Write-Host "Status of Rsat.ActiveDirectory.DS-LDS.Tools~~~~0.0.1.0 Package on VM and status"
        Write-Host $x2[0].Name
        Write-Host $x2[0].State

        Write-Host "Running Get-Command Module ActiveDirectory"
        Get-Command -Module ActiveDirectory
        Write-Host "Completed running Get-Command Module ActiveDirectory"

         Write-Host "Running  Get-Command -Name Add-ADGroupMember"
        Get-Command -Name Add-ADGroupMember -ErrorAction SilentlyContinue
         Write-Host "Completed  Get-Command -Name Add-ADGroupMember"
    }
}

###################################################################################################
#
# Main execution block.
#

try
{
    if ($PSVersionTable.PSVersion.Major -lt 3)
    {
        throw "The current version of PowerShell is $($PSVersionTable.PSVersion.Major). Prior to running this artifact, ensure you have PowerShell 3 or higher installed."
    }

    Write-Host "Attempting to join computer $($Env:COMPUTERNAME) to domain $DomainToJoin."
    $securePass = ConvertTo-SecureString $DomainAdminPassword -AsPlainText -Force
    Join-Domain -DomainName $DomainToJoin -User $DomainAdminUsername -Password $securePass -OUPath $OUPath -ADGroup $ADGroup

    Write-Host 'Artifact applied successfully.'
}
finally
{
    Pop-Location
}