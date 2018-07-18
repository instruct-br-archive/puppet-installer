#!/bin/bash

### verificando se voce esta usando bash

if [ ! -n "${BASH}" ]; then
  echo "Esse script precisa ser executado pelo BASH"
  exit 1
fi

### variaveis

OS='undef'                                        # sistema operacional
HTTP_PORT='80'                                    # porta apache master
PUPPETMASTER='puppet.dev'                         # endereço do puppetmaster
PUPPETMASTER_PORT='8140'                          # porta do puppetmaster
PUPPETMASTER_CA='puppet.dev'                      # endereco do puppetca

LOGDIR="/tmp"                                     # diretorio pra logs
LOCKFILE="/tmp/installer.lock"                    # arquivo de lock
TIMESTAMP=$(date +%Y%m%d.%H%M%S)                  # variavel de data e hora
LOGFILE="$LOGDIR/installer.$TIMESTAMP.log"        # arquivo de log saida std
LOG="tee -a $LOGFILE"                             # configuracoes do log

### iniciando

if [ -f "${LOCKFILE}" ]; then
  echo "Installer lock encontrado em ${LOCKFILE}, verifique se o installer já está rodando"
  exit 1
fi

touch "${LOCKFILE}"
echo -e "Instalacao de agente iniciada em $(date +%Y%m%d.%H%M%S)...\n" |$LOG
echo -e "Os logs estao sendo gravados em $LOGFILE\n"

### verificando se voce esta rodando o script como root

if [ "$(id -u)" != "0" ];then
  echo -e "\nErro: este script precisa ser executado com usuario root " |$LOG
  echo -e "Ajuda: torne-se root, use o comando (su -) ou (sudo -i).\n" |$LOG
  exit 1
fi

### verificando se o curl ou wget estão instalados

which curl &> /dev/null
  if [ $? -eq 0 ]; then
  DOWNLOADER='curl -s -O'
else
  which wget &> /dev/null
  if [ $? -eq 0 ]; then
    DOWNLOADER='wget -q'
  else
    echo "Instale o curl ou o wget para prosseguir" |$LOG
    exit 1
  fi
fi

### iniciando deteccao do sistema operacional

###### EL7 ######
egrep '^CentOS Linux release 7' /etc/redhat-release &> /dev/null

if [ $? -eq 0 ]; then
  OS='el7'
fi

egrep '^Red Hat Enterprise Linux Server release 7' /etc/redhat-release &> /dev/null

if [ $? -eq 0 ]; then
  OS='el7'
fi

###### EL6 ######
egrep '^Red Hat Enterprise Linux Server release 6' /etc/redhat-release &> /dev/null

if [ $? -eq 0 ]; then
  OS='el6'
fi

egrep '^CentOS release 6' /etc/redhat-release &> /dev/null

if [ $? -eq 0 ]; then
  OS='el6'
fi

###### EL5 ######

egrep '^CentOS release 5' /etc/redhat-release &> /dev/null

if [ $? -eq 0 ]; then
  OS='el5'
fi

egrep '^Red Hat Enterprise Linux Server release 5' /etc/redhat-release &> /dev/null

if [ $? -eq 0 ]; then
  OS='el5'
fi


###### Debian 6 squeeze ######
egrep '^6\.' /etc/debian_version &> /dev/null

if [ $? -eq 0 ]; then
  OS='squeeze'
fi

###### Debian 7 wheezy ######
egrep '^7\.' /etc/debian_version &> /dev/null

if [ $? -eq 0 ]; then
  OS='wheezy'
fi

###### Debian 8 jessie ######
egrep '^8\.' /etc/debian_version &> /dev/null

if [ $? -eq 0 ]; then
  OS='jessie'
fi

###### Debian 9 stretch ######
egrep '^9\.' /etc/debian_version &> /dev/null

if [ $? -eq 0 ]; then
  OS='stretch'
fi

###### Ubuntu 12 precise ######
egrep 'DISTRIB_CODENAME=precise' /etc/lsb-release &> /dev/null

if [ $? -eq 0 ]; then
  OS='precise'
fi

###### Ubuntu 14 trusty ######
egrep 'DISTRIB_CODENAME=trusty' /etc/lsb-release &> /dev/null

if [ $? -eq 0 ]; then
  OS='trusty'
fi

###### Ubuntu 16 xenial ######
egrep 'DISTRIB_CODENAME=xenial' /etc/lsb-release &> /dev/null

if [ $? -eq 0 ]; then
  OS='xenial'
fi

###### Ubuntu 18 xenial ######
egrep 'DISTRIB_CODENAME=bionic' /etc/lsb-release &> /dev/null

if [ $? -eq 0 ]; then
  OS='bionic'
fi

###### sles 12 ######
egrep '^SUSE Linux Enterprise Server 12' /etc/SuSE-release &> /dev/null

if [ $? -eq 0 ]; then
  OS='sles12'
fi

###### sles 11 ######
egrep '^SUSE Linux Enterprise Server 11' /etc/SuSE-release &> /dev/null

if [ $? -eq 0 ]; then
  OS='sles11'
fi

### saindo se o sistema nao foi reconhecido

if [ "$OS" = 'undef' ]; then
  echo "Nao foi possivel detectar o sistema operacional ou o sistema operacional nao esta homologado" |$LOG
  exit 1
fi

### em caso de sistema reconhecido, vamos instalar o puppet agent

echo "O sistema dectado foi ${OS}" |$LOG
echo "Esta correto? [s/n]"
read RESPOSTA
if [ "$RESPOSTA" != "s" ]; then
  rm -f "${LOCKFILE}"
  exit 1
fi

RUN=true
while $RUN; do
  echo "Entre com o ID do PERSA:"
  read ID_PERSA

  echo "Entre com o nome do CLIENTE:"
  read CLIENTE_RAW

  CLIENTE=$(echo "${CLIENTE_RAW}" | tr '[:upper:]' '[:lower:]')

  echo "${ID_PERSA}" | egrep '[0-9]+' &> /dev/null
  if [ $? -ne 0 ]; then
    echo "ID do PERSA invalido"| $LOG
    continue
  fi

  echo "Nome final: ${ID_PERSA}.${CLIENTE}" | $LOG
  echo "Correto? [s/n]"
  read RESPOSTA

  if [ "$RESPOSTA" = "s" ]; then
    RUN=false
  fi

done

### tratando centos e redhat ###################

if [[ "$OS" =~ ^el[567]$ ]]; then
  yum clean >> "${LOGFILE}" 2>&1
  yum clean all >> "${LOGFILE}" 2>&1
fi

if [[ "$OS" =~ ^el[5]$ ]]; then
  export LC_ALL="C"
  echo "Instalando repositorio puppet para rhel 5" | $LOG
  cd /tmp
  $DOWNLOADER http://yum.puppet.com/puppet5/puppet5-release-el-5.noarch.rpm >> "${LOGFILE}" 2>&1
  rpm -ivh /tmp/puppet5-release-el-5.noarch.rpm >> "${LOGFILE}" 2>&1
fi

if [[ "$OS" =~ ^el[6]$ ]]; then
  echo "Instalando repositorio puppet para rhel 6" | $LOG
  export LC_ALL="C"
  yum install -y http://yum.puppet.com/puppet5/puppet5-release-el-6.noarch.rpm >> "${LOGFILE}" 2>&1
fi

if [[ "$OS" =~ ^el[7]$ ]]; then
  echo "Instalando repositorio puppet para rhel 7" | $LOG
  export LC_ALL="C"
  yum install -y http://yum.puppet.com/puppet5/puppet5-release-el-7.noarch.rpm >> "${LOGFILE}" 2>&1
fi

if [[ "$OS" =~ ^el[567]$ ]]; then
  echo "Instalando o agente puppet" | $LOG
  yum install -y puppet-agent >> "${LOGFILE}" 2>&1
fi

### tratando familia debian ###################

if [[ "$OS" =~ ^(squeeze|wheezy|jessie|stretch|precise|trusty|xenial|bionic)$ ]]; then
  echo "Checando se repositorio cdrom esta ativado" | $LOG
  egrep '^deb cdrom:' /etc/apt/sources.list /etc/apt/sources.list.d/* &> /dev/null
  if [ $? -eq 0 ]; then
    echo "Existe uma fonte do tipo CDROM configurada no APT." | $LOG
    echo "Remova e excute o instalador novamente." | $LOG
    exit 1
  else
    echo "Nao detectei repositorios em cdrom" | $LOG
  fi

  # instalando repo em debian 6, 7, 8 e 9

  cd /tmp

  if [[ "$OS" =~ ^(squeeze)$ ]]; then
    echo "Instalando repositorio puppet para debian squeeze" | $LOG
    $DOWNLOADER http://apt.puppet.com/pool/squeeze/PC1/p/puppetlabs-release-pc1/puppetlabs-release-pc1_1.1.0-4squeeze_all.deb >> "${LOGFILE}" 2>&1
    dpkg -i puppetlabs-release-pc1_1.1.0-4squeeze_all.deb >> "${LOGFILE}" 2>&1
  fi

  if [[ "$OS" =~ ^(wheezy)$ ]]; then
    echo "Instalando repositorio puppet para debian wheezy" | $LOG
    $DOWNLOADER http://apt.puppet.com/pool/wheezy/puppet5/p/puppet5-release/puppet5-release_5.0.0-1wheezy_all.deb >> "${LOGFILE}" 2>&1
    dpkg -i puppet5-release_5.0.0-1wheezy_all.deb >> "${LOGFILE}" 2>&1
  fi

  if [[ "$OS" =~ ^(jessie)$ ]]; then
    echo "Instalando repositorio puppet para debian jessie" | $LOG
    $DOWNLOADER http://apt.puppet.com/pool/jessie/puppet5/p/puppet5-release/puppet5-release_5.0.0-1jessie_all.deb >> "${LOGFILE}" 2>&1
    dpkg -i puppet5-release_5.0.0-1jessie_all.deb >> "${LOGFILE}" 2>&1
  fi

  if [[ "$OS" =~ ^(stretch)$ ]]; then
    echo "Instalando repositorio puppet para debian stretch" | $LOG
    $DOWNLOADER http://apt.puppet.com/pool/stretch/puppet5/p/puppet5-release/puppet5-release_5.0.0-1stretch_all.deb >> "${LOGFILE}" 2>&1
    dpkg -i puppet5-release_5.0.0-1stretch_all.deb >> "${LOGFILE}" 2>&1
  fi

  # instalando repo em ubuntu 12, 14, 16 e 18

  if [[ "$OS" =~ ^(precise)$ ]]; then
    echo "Instalando repositorio puppet para ubuntu precise" | $LOG
    $DOWNLOADER http://apt.puppet.com/pool/precise/PC1/p/puppetlabs-release-pc1/puppetlabs-release-pc1_1.1.0-4precise_all.deb >> "${LOGFILE}" 2>&1
    dpkg -i puppetlabs-release-pc1_1.1.0-4precise_all.deb >> "${LOGFILE}" 2>&1
  fi

  if [[ "$OS" =~ ^(trusty)$ ]]; then
    echo "Instalando repositorio puppet para ubuntu trusty" | $LOG
    $DOWNLOADER http://apt.puppet.com/pool/trusty/puppet5/p/puppet-release/puppet-release_1.0.0-1trusty_all.deb >> "${LOGFILE}" 2>&1
    dpkg -i puppet-release_1.0.0-1trusty_all.deb >> "${LOGFILE}" 2>&1
  fi

  if [[ "$OS" =~ ^(xenial)$ ]]; then
    echo "Instalando repositorio puppet para ubuntu xenial" | $LOG
    $DOWNLOADER http://apt.puppet.com/pool/xenial/puppet5/p/puppet5-release/puppet5-release_5.0.0-1xenial_all.deb >> "${LOGFILE}" 2>&1
    dpkg -i puppet5-release_5.0.0-1xenial_all.deb >> "${LOGFILE}" 2>&1
  fi

  if [[ "$OS" =~ ^(bionic)$ ]]; then
    echo "Instalando repositorio puppet para ubuntu bionic" | $LOG
    $DOWNLOADER   http://apt.puppet.com/pool/bionic/puppet5/p/puppet5-release/puppet5-release_5.0.0-2bionic_all.deb >> "${LOGFILE}" 2>&1
    dpkg -i puppet5-release_5.0.0-2bionic_all.deb >> "${LOGFILE}" 2>&1
  fi

  # instalando repo em ubuntu

  echo "Verificando logs do apt em busca de erros" | $LOG
  grep -i error /var/log/apt/*.log >> "${LOGFILE}" 2>&1
  if [ $? -eq 0 ]; then
    echo "Erro detectado nos logs do apt" | $LOG
    echo "Deseja continuar mesmo assim? [s/n]"
    read RESPOSTA
    if [ "${RESPOSTA}" == "n" ];then
      exit 1
    fi
  fi

  echo "Verificando consistencia de base de dados dpkg" | $LOG
  apt-get check 2>&1 | $LOG
  if [ $? -ne 0 ]; then
    echo "Erro na verificacao do apt-get check" | $LOG
    echo "Deseja continuar mesmo assim? [s/n]"
    read RESPOSTA
    if [ "${RESPOSTA}" == "n" ];then
      exit 1
    fi
  fi

  echo "Simulando instalacao de pacote para checar apt" | $LOG
  apt-get install -s atop >> "${LOGFILE}" 2>&1
  if [ $? -ne 0 ]; then
    echo "Erro na simulacao de instalacao de pacote" | $LOG
    echo "Deseja continuar mesmo assim? [s/n]"
    read RESPOSTA
    if [ "${RESPOSTA}" == "n" ];then
      exit 1
    fi
  fi

  echo "Atualizando indices de pacotes debian" | $LOG
  apt-get update >> "${LOGFILE}" 2>&1
  if [ $? -ne 0 ]; then
    echo "A configuracao do APT dessa maquina esta com problema."
    echo "Isso pode comprometer o gerenciamento de pacotes pelo Puppet."
    echo "Corrija erros nas configuracoes dos repositorios."
    exit 1
  else
    echo "Indices apt atualizados com sucesso" | $LOG
  fi

  export LC_ALL="C"
  echo "Instalando agente puppet" | $LOG
  apt-get install puppet-agent -y >> "${LOGFILE}" 2>&1
fi

### tratando sles ###################

if [[ "$OS" =~ ^sles11$ ]]; then
  cd /tmp
  echo "Instalando repositorio puppet para suse 11" | $LOG
  $DOWNLOADER http://yum.puppet.com/puppet5/sles/11/x86_64/puppet5-release-5.0.0-1.sles11.noarch.rpm >> "${LOGFILE}" 2>&1
  zypper install puppet5-release-5.0.0-1.sles11.noarch.rpm >> "${LOGFILE}" 2>&1
fi

if [[ "$OS" =~ ^sles12$ ]]; then
  cd /tmp
  echo "Instalando repositorio puppet para suse 12" | $LOG
  $DOWNLOADER http://yum.puppet.com/puppet5/sles/12/x86_64/puppet5-release-5.0.0-1.sles12.noarch.rpm >> "${LOGFILE}" 2>&1
  zypper install puppet5-release-5.0.0-1.sles12.noarch.rpm >> "${LOGFILE}" 2>&1
fi

if [[ "$OS" =~ ^sles1[12]$ ]]; then

  echo "Verificando consistencia de base de dados zypper" | $LOG
  zypper verify 2>&1 >> "${LOGFILE}" 2>&1
  if [ $? -ne 0 ]; then
    echo "Erro na verificacao do zypper verify" | $LOG
    echo "Deseja continuar mesmo assim? [s/n]"
    read RESPOSTA
    if [ "${RESPOSTA}" == "n" ];then
      exit 1
    fi
  else
    echo "Verificacao da base de dados do zypper concluida com sucesso"
  fi

  echo "Atualizando indices zypper" | $LOG
  zypper refresh >> "${LOGFILE}" 2>&1
  if [ $? -ne 0 ]; then
    echo "Erro na atualizacao de indices do zypper" | $LOG
    echo "Deseja continuar mesmo assim? [s/n]"
    read RESPOSTA
    if [ "${RESPOSTA}" == "n" ];then
      exit 1
    fi
  else
    echo "Indices do zypper atualizados com sucesso"
  fi

  echo "Instalando agente puppet" | $LOG
  zypper install puppet-agent >> "${LOGFILE}" 2>&1
fi

### configurando arquivo puppet.conf

echo "Configurando arquivo puppet.conf" | $LOG

cat <<EOF > /etc/puppetlabs/puppet/puppet.conf
[main]
    ca_server         = ${PUPPETMASTER_CA}
    server            = ${PUPPETMASTER}
[agent]
    environment       = production
    certname          = ${ID_PERSA}.${CLIENTE}
EOF

### verificando ferramentas para teste de conexao no master em sistemas rhel like

#el5/6
if [[ "$OS" =~ ^el[56]$ ]]; then
  echo "Verificando se netcat esta instalado" | $LOG
  which nc &> /dev/null
  if [ $? -ne 0 ]; then
      echo "Nao detectei o netcat, posso instalar" | $LOG
      echo "Voce aceita? [s,n]"
      read RESPOSTA
      if [ "${RESPOSTA}" == "n" ];then
        exit 1
      else
        echo "Instalando NC" | $LOG
        yum -y install nc >> "${LOGFILE}" 2>&1
      fi
  fi
  ## testando conexao com o master
  echo "Testando conexao com o PuppetMaster" | $LOG
  nc -z $PUPPETMASTER $PUPPETMASTER_PORT >> "${LOGFILE}" 2>&1
  if [ $? -ne 0 ]; then
    echo "Nao consegui conexao com o puppet master." | $LOG
    exit 1
  else
    echo "Conexao ao puppetmaster ok" | $LOG
  fi
fi

#el7
if [[ "$OS" =~ ^el[7]$ ]]; then
  echo "Verificando se tcping esta instalado" | $LOG
  which tcping &> /dev/null
  if [ $? -ne 0 ]; then
      echo "Nao detectei o tcping, posso instalar" | $LOG
      echo "Voce aceita? [s,n]"
      read RESPOSTA
      if [ "${RESPOSTA}" == "n" ];then
        exit 1
      else
        sleep 5
        echo "Instalando TCPING" | $LOG
	yum -y install epel-release >> "${LOGFILE}" 2>&1
        yum -y install tcping >> "${LOGFILE}" 2>&1
      fi
  fi
  ## testando conexao com o master
  echo "Verificando conexao com o master" | $LOG
  tcping $PUPPETMASTER $PUPPETMASTER_PORT >> "${LOGFILE}" 2>&1
  if [ $? -ne 0 ]; then
    echo "Nao consegui conexao com o puppet master." | $LOG
    exit 1
  else
    echo "Conexao ao puppetmaster ok" | $LOG
  fi
fi

### verificando ferramentas para teste de conexao no master em sistemas debian like

if [[ "$OS" =~ ^(squeeze|wheezy|jessie|stretch|lucid|precise|trusty|xenial)$ ]]; then
    which nc &> /dev/null
    if [ $? -ne 0 ]; then
        echo "Nao detectei o netcat, posso instalar" | $LOG
        echo "Posso instalar, voce aceita? [s,n]"
        read RESPOSTA
        if [ "${RESPOSTA}" == "n" ];then
          exit 1
        else
          sleep 20
          apt-get -y install netcat-openbsd >> "${LOGFILE}" 2>&1
        fi
    fi
    ## testando conexao com o master
    nc -z $PUPPETMASTER $PUPPETMASTER_PORT >> "${LOGFILE}" 2>&1
    if [ $? -ne 0 ]; then
      echo "Nao consegui conexao com o puppet master." | $LOG
      exit 1
    else
      echo "Conexao ao puppetmaster ok" | $LOG
    fi
fi

### verificando ferramentas para teste de conexao no master em sistemas sles

# sles11
if [[ "$OS" =~ ^sles11$ ]]; then
    which netcat &> /dev/null
    if [ $? -ne 0 ]; then
        echo "Nao detectei o netcat, posso instalar" | $LOG
        echo "Posso instalar, voce aceita? [s,n]"
        read RESPOSTA
        if [ "${RESPOSTA}" == "n" ];then
          exit 1
        else
          zypper install netcat >> "${LOGFILE}" 2>&1
        fi
    fi
    ## testando conexao com o master
    netcat -z $PUPPETMASTER $PUPPETMASTER_PORT >> "${LOGFILE}" 2>&1
    if [ $? -ne 0 ]; then
      echo "Nao consegui conexao com o puppet master." | $LOG
      exit 1
    else
      echo "Conexao ao puppetmaster ok" | $LOG
    fi
fi

# sles12
if [[ "$OS" =~ ^sles12$ ]]; then
    which nc &> /dev/null
    if [ $? -ne 0 ]; then
        echo "Nao detectei o netcat, posso instalar" | $LOG
        echo "Posso instalar, voce aceita? [s,n]"
        read RESPOSTA
        if [ "${RESPOSTA}" == "n" ];then
          exit 1
        else
          zypper install netcat-openbsd >> "${LOGFILE}" 2>&1
        fi
    fi
    ## testando conexao com o master
    nc -z $PUPPETMASTER $PUPPETMASTER_PORT >> "${LOGFILE}" 2>&1
    if [ $? -ne 0 ]; then
      echo "Nao consegui conexao com o puppet master." | $LOG
      exit 1
    else
      echo "Conexao ao puppetmaster ok" | $LOG
    fi
fi

### iniciando comunicacao com puppetmaster

/opt/puppetlabs/bin/puppet agent

### finalizando
rm -f "${LOCKFILE}"
echo -e "Instalacao de agente finalizada em $(date +%Y%m%d.%H%M%S)...\n" | $LOG
echo -e "Veja o log em detalhes no arquivo $LOGFILE \n"
