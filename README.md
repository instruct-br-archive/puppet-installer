# Puppet Installer

This project contains a BASH script to install Puppet Agent on Linux machines, and a PowerShell script to install it on Windows machines.

## Compatibility

The script was tested on these operating systems:

- EL 5, 6 and 7
- Debian 6, 7, 8, and 9
- Ubuntu 12.04, 14.04, 16.04 and 18.04
- SLES 11 and 12
- Windows 2008, 2012 e 2016

On Ubuntu 12.04 and Debian 6 the last available package is from Puppet 4 series. All others OSes can use Puppet 5 versions.

## Using

### On Linux hosts

Download this script (read it before!) and run it in the host, as root:

    # curl -s https://raw.githubusercontent.com/instruct-br/puppet-installer/master/installer.sh | bash -s [certname]

The script will use the first parameter as the certificate name, if available, or the value from `certname` environment variable, if defined. The env variable have precedence, if both values are defined, and the script will fail if the `certname` is not defined.

Some environment variables can be declared so the script will consider them during the install. This is the list:

- `puppet`: configure the Puppet Server to provide the catalogs. Defaults to `puppet`;
- `port`: configure the Puppet Server (and CA) port to connect. Defaults to *8140*;
- `ca_server`: configure the Puppet Server CA to sign the certificate. Defaults to `puppet`;
- `environment`: configure the environment the catalog will come from. Defaults to `production`.
- `certname`: configure the host certname. This value has precedence over the command line parameter.
- `runinterval`: configure the client run interval. Defaults to 180 seconds.
- `waitforcert`: configure the wait time for certificate signing. Defaults to 30 seconds.

The suggestion is to export the expected values, so the script will use them:

    # export puppet=mypuppetserver.company.com

To enable a debug while running the script it is also possible to export the variable DEBUG, with any content:

    # export DEBUG=true

### On Windows hosts

Download this script from this URL:

    https://raw.githubusercontent.com/instruct-br/puppet-installer/master/installer.ps1

Then run it like this, as administrator:

    c:\> powershell.exe -ExecutionPolicy Unrestricted -NoLogo -NoProfile -Command "& '.\installer.ps1'"

Some variables can be declared so the script will consider them during the install. This is the list:

- `PuppetServer`: configure the Puppet Server to provide the catalogs. Defaults to `puppet`;
- `PuppetCAServer`: configure the Puppet Server CA to sign the certificate. Defaults to `puppet`;
- `PuppetEnvironment`: configure the environment the catalog will come from. Defaults to `production`.
- `PuppetCertname`: configure the host certname. This value is obligatory, and will be prompted if not specified.
- `PuppetRuninterval`: configure the client run interval. Defaults to 180 seconds.
- `PuppetWaitForCert`: configure the wait time for certificate signing. Defaults to 30 seconds.
