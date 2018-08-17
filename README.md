# Puppet Installer

This project contains a BASH script to install Puppet Agent.

## Compatibility

The script was tested on these operating systems:

- EL 5, 6 and 7
- Debian 6, 7, 8, and 9
- Ubuntu 12.04, 14.04, 16.04 and 18.04
- SLES 11 and 12

On Ubuntu 12.04 and Debian 6 the last available package is from Puppet 4 series. All others OSes can use Puppet 5 versions.

## Using

Download this script (read it before!) and run it in the host, as root:

    # curl https://raw.githubusercontent.com/instruct-br/puppet-installer/master/installer.sh | bash -s

The script will use the hostname and domain for the certificate name.

Some environment variables can be declared so the script will consider them during the install. This is the list:

- `puppet`: configure the Puppet Server to provide the catalogs. Defaults to `puppet`;
- `port`: configure the Puppet Server (and CA) port to connect. Defaults to *8140*;
- `ca_server`: configure the Puppet Server CA to sign the certificate. Defaults to `puppet`;
- `environment`: configure the environment the catalog will come from. Defaults to `production`.

The suggestion is to export the expected values, so the script will use them:

    # export puppet=mypuppetserver.company.com

To enable a debug while running the script it is also possible to export the variable DEBUG, with any content:

    # export DEBUG=true
