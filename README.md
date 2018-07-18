# Puppet Installer

Esse projeto contém um script que faz a instalação do puppet agent.

## Compatibilidade

- EL 5, 6 e 7
- Debian 6, 7, 8, e 9
- Ubuntu 12, 14, 16 e 18
- SLES 11 e 12

No caso de Ubuntu 12 e Debian 6 é instalada a última versão da série 4, nos demais OSes é instalada a versão corrente da série 5.

## Utilizando

Faça o download do script

    # wget https://git.mop.equinix.com.br/equinix-puppet/puppet-installer/blob/master/installer.sh

Execute o script

    # bash installer.sh

O script irá perguntar ID do PERSA e nome do CLIENTE, basta responder estas duas questões para ter o agente instalado.
