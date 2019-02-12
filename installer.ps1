<#
Originally developed by Hashicorp.
Source: https://raw.githubusercontent.com/hashicorp/puppet-bootstrap/master/windows.ps1

.SYNOPSIS
    Installs Puppet on this machine.

.DESCRIPTION
    Downloads and installs the official Puppet MSI package.

    This script requires administrative privileges.

    You can run this script from an old-style cmd.exe prompt using the
    following:

      powershell.exe -ExecutionPolicy Unrestricted -NoLogo -NoProfile -Command "& '.\installer.ps1'"

.PARAMETER MsiUrl
    This is the URL to the Puppet MSI file you want to install. This defaults
    to latest version from Puppet 5.

.PARAMETER PuppetCAServer
    This is the name of Puppet Server CA that will sign the agent keys.
    This defaults to 'one.mop.equinix.com.br'.

.PARAMETER PuppetCertname
    This is the name Puppet agent will present itself to the Server.

.PARAMETER PuppetEnvironment
    This is the name of the Puppet environment the catalog will come from.
    This defaults to 'production'.

.PARAMETER PuppetRunInterval
    The interval, in seconds, between Puppet agent runs.
    Defaults to 180 seconds.

.PARAMETER PuppetServer
    This is the name of Puppet Server that will provide the catalogs.
    This defaults to 'master.mop.equinix.com.br'.

.PARAMETER PuppetVersion
    This is the version of Puppet that you want to install. If you pass this it will override the version in the MsiUrl.
    This defaults to $null.

.PARAMETER PuppetWaitForCert
    The period, in seconds, the Puppet agent will wait for the certificate to be signed.
    Defaults to 30 secoonds.

.PARAMETER Purge
    This forces the script to remove a previous install, if present.
    Default to false.#>
param(
    [string]$MsiUrl = "https://downloads.puppet.com/windows/puppet5/puppet-agent-x64-latest.msi",
    [string]$PuppetCAServer = "one.mop.equinix.com.br",

    [Parameter(
        Mandatory=$True,
        HelpMessage="Enter the Puppet agent certname"
    )]
    [string]$PuppetCertname = $null,
    [string]$PuppetEnvironment = "production",
    [string]$PuppetRunInterval = "180",
    [string]$PuppetServer = "master.mop.equinix.com.br",
    [string]$PuppetVersion = $null,
    [string]$PuppetWaitForCert = "30",
    [switch]$Purge = $false
)

if ($PuppetVersion) {
    $MsiUrl = "https://downloads.puppet.com/windows/puppet5/puppet-agent-$($PuppetVersion)-x64.msi"
    Write-Output "Puppet version $PuppetVersion specified, updated MsiUrl to `"$MsiUrl`""
}

$PuppetInstalled = $false
try {
    $ErrorActionPreference = "Stop";
    Get-Command puppet | Out-Null
    $PuppetInstalled = $true
    $PuppetVersion = &puppet "--version"
    if (!($Purge)) {
      Write-Output "Puppet $PuppetVersion is installed and the purge flag was not used. This process does not ensure the exact version or at least version specified, but only that puppet is installed. Exiting..."
      Exit 0
    } else {
      Write-Output "Puppet $PuppetVersion is installed and will be removed..."
      $Puppet = Get-WmiObject -Class Win32_Product | Where-Object {
                    $_.Name -match "puppet"
                }
      $Puppet.Uninstall() | out-null
      Write-Output "Cleaning Puppet directories..."
      Remove-Item -Path C:\ProgramData\PuppetLabs -recurse
      $PuppetInstalled = $false
    }
} catch {
    Write-Output "Puppet is not installed, continuing..."
}

if (!($PuppetInstalled)) {
    $currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
    if (! ($currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator))) {
        Write-Output -ForegroundColor Red "You must run this script as an administrator."
        Exit 1
    }

    # Install it - msiexec will download from the url
    $install_args = @(
        "/qn",
        "/norestart",
        "/i",
        $MsiUrl,
        "PUPPET_MASTER_SERVER=$PuppetServer",
        "PUPPET_CA_SERVER=$PuppetCAServer",
        "PUPPET_AGENT_ENVIRONMENT=$PuppetEnvironment"
    )

    if ($PuppetCertname) {
        Write-Output "Configuring certname as $PuppetCertname"
        $install_args += "PUPPET_AGENT_CERTNAME=$($PuppetCertname)"
    }

    Write-Output "Installing Puppet. Running msiexec.exe $install_args"
    $process = Start-Process -FilePath msiexec.exe -ArgumentList $install_args -Wait -PassThru
    if ($process.ExitCode -ne 0) {
        Write-Output "Installer failed."
        Exit 1
    }

    echo "[agent]"                        | out-file -append -encoding ASCII C:/ProgramData/PuppetLabs/puppet/etc/puppet.conf
    echo "runinterval=$PuppetRunInterval" | out-file -append -encoding ASCII C:/ProgramData/PuppetLabs/puppet/etc/puppet.conf
    echo "waitforcert=$PuppetWaitForCert" | out-file -append -encoding ASCII C:/ProgramData/PuppetLabs/puppet/etc/puppet.conf

    # Stop the service that it autostarts
    Write-Output "Stopping Puppet service that is running by default..."
    Start-Sleep -s 5
    Stop-Service -Name puppet

    Write-Output "Puppet successfully installed."
}
