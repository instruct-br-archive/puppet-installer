#!/bin/bash
# set -euo pipefail
IFS=$'\n\t'

### Set here your environment configuration

PUPPET_SERVER=${puppet:-'puppet'}                 # Puppet Server host
PUPPET_SERVER_PORT=${port:-'8140'}                # Puppet Server port
PUPPET_SERVER_CA=${ca_server:-'puppet'}           # Puppet CA Server host
PUPPET_ENVIRONMENT=${environment:-'production'}   # Puppet environment
PUPPET_RUN_INTERVAL=${runinterval:-'180'}   # Puppet run interval
PUPPET_WAIT_FOR_CERT=${waitforcert:-'30'}   # Puppet wait for cert
PUPPET_CERTNAME=${certname:-$1}

: "${PUPPET_CERTNAME?"Usage: $0 certname"} "

LOGDIR="/var/log"                                 # logs folder
LOCKFILE="/tmp/puppet.installer.lock"             # lock file
TIMESTAMP=$(date -u +%Y%m%d.%H%M%S)               # run timestamp, UTC
LOGFILE="$LOGDIR/puppet.installer.$TIMESTAMP.log" # standard out log file
OS='undef'                                        # detected operating system
PURGE=false                                       # whether to clean a previous install or not

log() {
  echo -e "====>>>> $1" | tee -a "$LOGFILE"
}

check_bash() {
  if [ ! -n "${BASH}" ]; then
    echo "This script only works on BASH shell"
    exit 1
  elif [ -n "${DEBUG}" ]; then
    echo "===== PARAMETERS ====="
    echo "Puppet Server CA: ${PUPPET_SERVER_CA}"
    echo "Puppet Server: ${PUPPET_SERVER}"
    echo "Puppet Server port: ${PUPPET_SERVER_PORT}"
    echo "Puppet Server environment: ${PUPPET_ENVIRONMENT}"
    echo "Puppet certname: ${PUPPET_CERTNAME}"
    echo "===== ===== ====="
  fi
}

check_root() {
  ID=$(id -u)
  if [ "$ID" -ne 0 ]; then
    echo -e "\\nError: you must be root to run this script"
    echo -e "Become root with the command 'sudo -i'.\\n"
    exit 2
  fi
}

check_lock_file() {
  if [ -f "${LOCKFILE}" ]; then
    echo "Install lock found at ${LOCKFILE}, check if the script is already running"
    exit 3
  fi
}

create_lock_file() {
  mkdir -p "${LOGDIR}"
  touch "${LOGFILE}"
  touch "${LOCKFILE}"
  echo -e "Log messages are on $LOGFILE\\n"
  log "Puppet agent installation started at $(date -uIs)"
}

check_download_tool() {
  if hash curl &> /dev/null; then
    DOWNLOADER='curl -s -O'
    log "Found curl"
  else
    if hash wget &> /dev/null; then
      DOWNLOADER='wget -q'
      log "Found wget"
    else
      log "Failure: curl/wget not found but required to proceed."
      exit 4
    fi
  fi
}

check_os_el7() {
  if grep -E '^CentOS Linux release 7'                    /etc/redhat-release &> /dev/null || \
     grep -E '^Red Hat Enterprise Linux Server release 7' /etc/redhat-release &> /dev/null; then
    OS='el7'
    REPOURL='http://yum.puppet.com/puppet5/puppet5-release-el-7.noarch.rpm'
    CONNECTION_COMMAND='tcping'
    CONNECTION_TOOL='tcping'
    CONNECTION_PACKAGES='tcping'
    return 0
  else
    return 1
  fi
}

check_os_el6() {
  if grep -E '^CentOS release 6'                          /etc/redhat-release &> /dev/null || \
     grep -E '^Red Hat Enterprise Linux Server release 6' /etc/redhat-release &> /dev/null; then
    OS='el6'
    REPOURL='http://yum.puppet.com/puppet5/puppet5-release-el-6.noarch.rpm'
    CONNECTION_COMMAND='nc -z'
    CONNECTION_TOOL='nc'
    CONNECTION_PACKAGES='nc'
    return 0
  else
    return 1
  fi
}

check_os_el5() {
  if grep -E '^CentOS release 5'                          /etc/redhat-release &> /dev/null || \
     grep -E '^Red Hat Enterprise Linux Server release 5' /etc/redhat-release &> /dev/null; then
    OS='el5'
    REPOFILE='puppet5-release-el-5.noarch.rpm'
    REPOURL="http://yum.puppet.com/puppet5/$REPOFILE"
    CONNECTION_COMMAND='nc -z'
    CONNECTION_TOOL='nc'
    CONNECTION_PACKAGES='nc'
    return 0
  else
    return 1
  fi
}

check_os_debian6() {
  if grep -E '^6\.' /etc/debian_version &> /dev/null; then
    OS='squeeze'
    REPOURL='http://apt.puppet.com/pool/squeeze/PC1/p/puppetlabs-release-pc1/puppetlabs-release-pc1_1.1.0-4squeeze_all.deb'
    REPOFILE='puppetlabs-release-pc1_1.1.0-4squeeze_all.deb'
    return 0
  else
    return 1
  fi
}

check_os_debian7() {
  if grep -E '^7\.' /etc/debian_version &> /dev/null; then
    OS='wheezy'
    REPOFILE='puppet5-release_5.0.0-1wheezy_all.deb'
    REPOURL="http://apt.puppet.com/pool/wheezy/puppet5/p/puppet5-release/$REPOFILE"
    return 0
  else
    return 1
  fi
}

check_os_debian8() {
  if grep -E '^8\.' /etc/debian_version &> /dev/null; then
    OS='jessie'
    REPOFILE='puppet5-release_5.0.0-1jessie_all.deb'
    REPOURL="http://apt.puppet.com/pool/jessie/puppet5/p/puppet5-release/$REPOFILE"
    return 0
  else
    return 1
  fi
}

check_os_debian9() {
  if grep -E '^9\.' /etc/debian_version &> /dev/null; then
    OS='stretch'
    REPOFILE='puppet5-release_5.0.0-1stretch_all.deb'
    REPOURL="http://apt.puppet.com/pool/stretch/puppet5/p/puppet5-release/$REPOFILE"
    return 0
  else
    return 1
  fi
}

check_os_ubuntu12() {
  if grep -E 'DISTRIB_CODENAME=precise' /etc/lsb-release &> /dev/null; then
    OS='precise'
    REPOFILE='puppetlabs-release-pc1_1.1.0-4precise_all.deb'
    REPOURL="http://apt.puppet.com/pool/precise/PC1/p/puppetlabs-release-pc1/$REPOFILE"
    return 0
  else
    return 1
  fi
}

check_os_ubuntu14() {
  if grep -E 'DISTRIB_CODENAME=trusty' /etc/lsb-release &> /dev/null; then
    OS='trusty'
    REPOFILE='puppet-release_1.0.0-1trusty_all.deb'
    REPOURL="http://apt.puppet.com/pool/trusty/puppet5/p/puppet-release/$REPOFILE"
    return 0
  else
    return 1
  fi
}

check_os_ubuntu16() {
  if grep -E 'DISTRIB_CODENAME=xenial' /etc/lsb-release &> /dev/null; then
    OS='xenial'
    REPOFILE='puppet5-release_5.0.0-1xenial_all.deb'
    REPOURL="http://apt.puppet.com/pool/xenial/puppet5/p/puppet5-release/$REPOFILE"
    return 0
  else
    return 1
  fi
}

check_os_ubuntu18() {
  if grep -E 'DISTRIB_CODENAME=bionic' /etc/lsb-release &> /dev/null; then
    OS='bionic'
    REPOFILE='puppet5-release_5.0.0-2bionic_all.deb'
    REPOURL="http://apt.puppet.com/pool/bionic/puppet5/p/puppet5-release/$REPOFILE"
    return 0
  else
    return 1
  fi
}

check_os_sles12() {
  if grep -E '^SUSE Linux Enterprise Server 12' /etc/SuSE-release &> /dev/null; then
    OS='sles12'
    REPOFILE='puppet5-release-5.0.0-1.sles12.noarch.rpm'
    REPOURL="http://yum.puppet.com/puppet5/sles/12/x86_64/$REPOFILE"
    CONNECTION_COMMAND='nc -z'
    CONNECTION_TOOL='nc'
    CONNECTION_PACKAGES='netcat-openbsd'
    return 0
  else
    return 1
  fi
}

check_os_sles11() {
  if grep -E '^SUSE Linux Enterprise Server 11' /etc/SuSE-release &> /dev/null; then
    OS='sles11'
    REPOFILE='puppet5-release-5.0.0-1.sles11.noarch.rpm'
    REPOURL="http://yum.puppet.com/puppet5/sles/11/x86_64/$REPOFILE"
    CONNECTION_COMMAND='netcat -z'
    CONNECTION_TOOL='netcat'
    CONNECTION_PACKAGES='netcat'
    return 0
  else
    return 1
  fi
}

clean_lock_file() {
  rm -f "${LOCKFILE}"
  log "Puppet agent installation finished at $(date -u +%Y%m%d.%H%M%S)...\\n"
  echo -e "You can check details on file $LOGFILE \\n"
}

clean_install() {
  PACKAGE_MANAGER=$1
  if [ -d /opt/puppetlabs ] && [ $PURGE = true ]; then
    log "Removing old Puppet repo package"
    $PACKAGE_MANAGER remove -y puppet.*release >> "${LOGFILE}" 2>&1
    log "Removing old Puppet agent package"
    $PACKAGE_MANAGER remove -y puppet-agent >> "${LOGFILE}" 2>&1
    rm -rf /opt/puppetlabs >> "${LOGFILE}" 2>&1
    rm -rf /etc/puppetlabs >> "${LOGFILE}" 2>&1
  fi
}

install_agent_el() {
  if [[ "$OS" =~ ^el[567]$ ]]; then
    export LC_ALL="C"
    clean_install "yum"

    yum clean all >> "${LOGFILE}" 2>&1

    log "Installing Puppet repo for $OS"
    if [[ "$OS" =~ ^el[5]$ ]]; then
      {
        cd /tmp && \
        eval "$DOWNLOADER $REPOURL" && \
        rpm -ivh $REPOFILE && \
        rm -fv $REPOFILE && \
        cd - || return
      } >> "${LOGFILE}" 2>&1
    fi

    if [[ "$OS" =~ ^el[67]$ ]]; then
      yum install -y $REPOURL >> "${LOGFILE}" 2>&1
    fi

    log "Installing Puppet agent"
    yum install -y puppet-agent >> "${LOGFILE}" 2>&1

    if ! hash $CONNECTION_TOOL &> /dev/null; then
      log "Installing connection tool"
      yum -y install epel-release >> "${LOGFILE}" 2>&1
      yum -y install $CONNECTION_PACKAGES >> "${LOGFILE}" 2>&1
    fi

    echo "PUPPET_EXTRA_OPTS=--waitforcert=${PUPPET_WAIT_FOR_CERT}" >> /etc/sysconfig/puppet
    return 0
  else
    return 1
  fi
}

install_agent_debian_ubuntu() {
  if [[ "$OS" =~ ^(squeeze|wheezy|jessie|stretch|precise|trusty|xenial|bionic)$ ]]; then
    clean_install "apt-get"

    log "Installing Puppet repo for $OS"
    cd /tmp || return 1
    eval "$DOWNLOADER $REPOURL" >> "${LOGFILE}" 2>&1
    dpkg -i $REPOFILE >> "${LOGFILE}" 2>&1
    rm -f $REPOFILE
    cd - || return 1

    log "Verifying dpkg database consistency"
    apt-get check >> "${LOGFILE}" 2>&1

    log "Updating packages index"
    if apt-get update >> "${LOGFILE}" 2>&1; then
      log "Package index updated successfully"
    else
      log "Package index has issues. Check the log file at $LOGFILE"
    fi

    export LC_ALL="C"
    log "Installing Puppet agent"
    apt-get install puppet-agent -y >> "${LOGFILE}" 2>&1

    CONNECTION_COMMAND='nc -z'
    if ! hash nc &> /dev/null; then
      log "Installing connection tool"
      apt-get -y install netcat-openbsd >> "${LOGFILE}" 2>&1
    fi

    echo "PUPPET_EXTRA_OPTS=--waitforcert=${PUPPET_WAIT_FOR_CERT}" >> /etc/default/puppet
    return 0
  else
    return 1
  fi
}

install_agent_sles() {
  if [[ "$OS" =~ ^sles1[12]$ ]]; then
    clean_install "zypper"

    log "Installing Puppet repo for $OS"
    cd /tmp && \
    eval "$DOWNLOADER -O http://yum.puppetlabs.com/RPM-GPG-KEY-puppet" && \
    rpm --import RPM-GPG-KEY-puppet && \
    rm -f RPM-GPG-KEY-puppet && \
    eval "$DOWNLOADER $REPOURL" >> "${LOGFILE}" 2>&1
    zypper install --no-confirm $REPOFILE >> "${LOGFILE}" 2>&1
    rm -f $REPOFILE
    cd - || return

    log "Verifying zypper database consistency"
    zypper verify 2>&1 >> "${LOGFILE}" 2>&1

    log "Updating packages index"
    if zypper refresh >> "${LOGFILE}" 2>&1; then
      log "Package index updated successfully"
    else
      log "Package index has issues. Check the log file at $LOGFILE"
    fi

    log "Installing Puppet agent"
    zypper install --no-confirm puppet-agent >> "${LOGFILE}" 2>&1

    if ! hash $CONNECTION_TOOL &> /dev/null; then
      log "Installing connection tool"
      zypper install $CONNECTION_PACKAGES >> "${LOGFILE}" 2>&1
    fi

    echo "PUPPET_EXTRA_OPTS=--waitforcert=${PUPPET_WAIT_FOR_CERT}" >> /etc/sysconfig/puppet
    return 0
  else
    return 1
  fi
}

config_puppet_conf() {
  log "Configuring puppet.conf file"
  rm -f /etc/puppetlabs/puppet/puppet.conf
  /opt/puppetlabs/puppet/bin/puppet config set --section main  ca_server   "${PUPPET_SERVER_CA}"
  /opt/puppetlabs/puppet/bin/puppet config set --section main  server      "${PUPPET_SERVER}"
  /opt/puppetlabs/puppet/bin/puppet config set --section main  port        "${PUPPET_SERVER_PORT}"
  /opt/puppetlabs/puppet/bin/puppet config set --section agent environment "${PUPPET_ENVIRONMENT}"
  /opt/puppetlabs/puppet/bin/puppet config set --section agent certname    "${PUPPET_CERTNAME}"
  /opt/puppetlabs/puppet/bin/puppet config set --section agent runinterval "${PUPPET_RUN_INTERVAL}"
  /opt/puppetlabs/puppet/bin/puppet config set --section agent waitforcert "${PUPPET_WAIT_FOR_CERT}"
}

test_connection() {
  log "Testing Puppet Server CA connection"
  if eval "$CONNECTION_COMMAND $PUPPET_SERVER_CA $PUPPET_SERVER_PORT" >> "${LOGFILE}" 2>&1; then
    log "Connection to Puppet Server CA at $PUPPET_SERVER_CA:$PUPPET_SERVER_PORT ok."
    log "Testing Puppet Server connection"
    if eval "$CONNECTION_COMMAND $PUPPET_SERVER $PUPPET_SERVER_PORT" >> "${LOGFILE}" 2>&1; then
      log "Connection to Puppet Server at $PUPPET_SERVER:$PUPPET_SERVER_PORT ok."
      return 0
    else
      log "Could not connect to Puppet Server at $PUPPET_SERVER:$PUPPET_SERVER_PORT."
      return 1
    fi
  else
    log "Could not connect to Puppet Server CA at $PUPPET_SERVER_CA:$PUPPET_SERVER_PORT."
    return 1
  fi
}

run_puppet_agent() {
  /opt/puppetlabs/bin/puppet agent --test
}

show_help() {
  echo "Usage:	bash puppet-installer.sh [-h|--help] [-p|--purge certname] certname"
  echo "Install the Puppet agent and test the connection with the Puppet Server"
  echo " "
  echo "  -h, --help     Print this page"
  echo "  -p, --purge    Clean a previous Puppet install"
  echo " "
  echo "The script requires the certname parameter, or a \"certname\" environment variable"
  exit 1
}

while :; do
  case $1 in
    -h|-\?|--help)
      show_help
      exit
      ;;
    -p|--purge)
      PURGE=true
      if [ "$2" ]; then
        PUPPET_CERTNAME=$2
        break
      else
        if [ ! $certname ]; then
          echo 'Error: "--purge" requires a non-empty option argument.'
          exit 1
        else
          PUPPET_CERTNAME=$certname
          break
        fi
      fi
      ;;
    *)
      if ! [ "$2" ] && [ "$1" ]; then
        PUPPET_CERTNAME=$1
        break
      else
        if [ ! $certname ]; then
          echo 'Error: Wrong use of options/arguments. Use --help to see the command usage.'
          exit 1
        else
          PUPPET_CERTNAME=$certname
          break
        fi
      fi
      break
  esac
  shift
done

check_bash
check_root
check_lock_file
create_lock_file
check_download_tool

check_os_el7 || \
check_os_el6 || \
check_os_el5 || \
check_os_debian6 || \
check_os_debian7 || \
check_os_debian8 || \
check_os_debian9 || \
check_os_ubuntu12 || \
check_os_ubuntu14 || \
check_os_ubuntu16 || \
check_os_ubuntu18 || \
check_os_sles11 || \
check_os_sles12 || \
{
  log "Unexpected OS detected."
  exit 5
}

log "Detected OS: ${OS}"
install_agent_el || install_agent_debian_ubuntu || install_agent_sles || {
  log "Agent installation failed"
  exit 6
}

config_puppet_conf
test_connection && run_puppet_agent
clean_lock_file
