# Puppet Installer

Esse projeto contém um script que faz a instalação do agente do Puppet em sistemas Linux e Windows.

## Compatibilidade

- EL 5, 6 e 7
- Debian 6, 7, 8, e 9
- Ubuntu 12, 14, 16 e 18
- SLES 11 e 12
- Windows 2008, 2012 e 2016

No caso de Ubuntu 12 e Debian 6 é instalada a última versão da série 4, nos demais OSes é instalada a versão corrente da série 5.

## Utilizando

### Em sistemas Linux

Faça o download do script:

    # wget https://git.mop.equinix.com.br/equinix-puppet/puppet-installer/raw/master/installer.sh

Execute o script:

    # bash installer.sh <nome.do.host>

Algumas variáveis de ambiente podem ser declaradas para que o script as considere durante a instalação. Esta é a lista:

- `puppet`: configura o Puppet Server para entregar os catálogos. Padrão é `master.mop.equinix.com.br`;
- `port`: configura a porta do Puppet Server (e CA). Padrão é *8140*;
- `ca_server`: configura o Puppet Server CA para assinar o certificado. Padrão é `one.mop.equinix.com.br`;
- `environment`: configura o ambiente do cliente. Padrão é `production`.
- `certname`: configura o certname do cliente. Este valor tem precedencia sobre o valor da linha de comando.
- `runinterval`: configura o intervalo de execução do cliente. Padrão é 180 segundos.
- `waitforcert`: configura o tempo de espera para assinatura do certificado do cliente. Padrão é 30 segundos.

A sugestão é exportar os valores esperados para que o script use eles, desta forma:

    # export puppet=mypuppetserver.company.com

Para habilitar o modo debug durante a execução do script basta exportar a variável DEBUG, com qualquer valor, desta forma:

    # export DEBUG=true

### Em sistemas Windows

Faça o download do script a partir desta URL:

    https://git.mop.equinix.com.br/equinix-puppet/puppet-installer/raw/master/installer.ps1

Execute o script:

    c:\> powershell.exe -ExecutionPolicy Unrestricted -NoLogo -NoProfile -Command "& '.\installer.ps1'"

Algumas variáveis podem ser declaradas para que o script as considere durante a instalação. Esta é a lista:

- `PuppetServer`: configura o Puppet Server para entregar os catálogos. Padrão é `master.mop.equinix.com.br`;
- `PuppetCAServer`: configura o Puppet Server CA para assinar o certificado. Padrão é `one.mop.equinix.com.br`;
- `PuppetEnvironment`: configura o ambiente do cliente. Padrão é `production`.
- `PuppetCertname`: configura o certname do cliente. Este valor é obrigatório, e será solicitado se não passado.
