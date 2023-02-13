#!/bin/bash

# Name: robox_altinity.sh
# Author: Myroslav Tkachenko
#
# Description: Used to build Altinity github machines on Ubuntu 22.04 using packer.

# Handle self referencing, sourcing etc.
if [[ $0 != $BASH_SOURCE ]]; then
  export CMD=$BASH_SOURCE
else
  export CMD=$0
fi

# Ensure a consistent working directory so relative paths work.
pushd `dirname $CMD` > /dev/null
BASE=`pwd -P`
popd > /dev/null
cd $BASE

# Credentials and tokens.
if [ ! -f $BASE/.credentialsrc ]; then
cat << EOF > $BASE/.credentialsrc
#!/bin/bash
# Overrides the repo version string with a default value.
[ ! -n "\$VERSION" ] && VERSION="1.0.0"

# Set the following to override default values.
# [ ! -n "\$GOMAXPROCS" ] && export GOMAXPROCS="2"

# [ ! -n "\$PACKER_ON_ERROR" ] && export PACKER_ON_ERROR="cleanup"
# [ ! -n "\$PACKER_MAX_PROCS" ] && export PACKER_MAX_PROCS="2"
[ ! -n "\$PACKER_CACHE_DIR" ] && export PACKER_CACHE_DIR="$BASE/packer_cache/"
#
# [ ! -n "\$QUAY_USER" ] && export QUAY_USER="LOGIN"
# [ ! -n "\$QUAY_PASSWORD" ] && export QUAY_PASSWORD="PASSWORD"
# [ ! -n "\$DOCKER_USER" ] && export DOCKER_USER="LOGIN"
# [ ! -n "\$DOCKER_PASSWORD" ] && export DOCKER_PASSWORD="PASSWORD"
# [ ! -n "\$VAGRANT_CLOUD_TOKEN" ] && export VAGRANT_CLOUD_TOKEN="TOKEN"

# Update the following if using provider.sh to install VMWare Workstation.
# [ ! -n "\$VMWARE_WORKSTATION" ] && export VMWARE_WORKSTATION="SERIAL"

EOF
tput setaf 1; printf "\n\nCredentials file was missing. Stub file created.\n\n\n"; tput sgr0
sleep 5
fi

# Import the credentials.
source $BASE/.credentialsrc

# Version Information
[ ! -n "$VERSION" ] && export VERSION="4.2.12"
export AGENT="Vagrant/2.2.19 (+https://www.vagrantup.com; ruby2.7.4)"

# Limit the number of cpus packer will use and control how errors are handled.
[ ! -n "$GOMAXPROCS" ] && export GOMAXPROCS="2"
[ ! -n "$PACKER_ON_ERROR" ] && export PACKER_ON_ERROR="cleanup"
[ ! -n "$PACKER_MAX_PROCS" ] && export PACKER_MAX_PROCS="1"
[ ! -n "$PACKER_CACHE_DIR" ] && export PACKER_CACHE_DIR="$BASE/packer_cache/"

# The provider platforms.
ROBOX_PROVIDERS="libvirt"

# The namespaces.
ROBOX_NAMESPACES="altinity"

# A list of configs to skip during complete build operations.
export EXCEPTIONS=""

# The repository URLs, so we can catch any which might disappeared since the last build.

# Ubuntu 22.04
REPOS+=( "https://mirrors.edge.kernel.org/ubuntu/dists/jammy/InRelease" )

# Other URls Embedded inside configuration modules
RESOURCES+=( "https://archive.org/download/xenial_python3.6_deb/libpython3.6-minimal_3.6.13-1%2Bxenial2_amd64.deb" )
RESOURCES+=( "https://archive.org/download/xenial_python3.6_deb/libpython3.6-stdlib_3.6.13-1%2Bxenial2_amd64.deb" )
RESOURCES+=( "https://archive.org/download/xenial_python3.6_deb/python3.6_3.6.13-1%2Bxenial2_amd64.deb" )
RESOURCES+=( "https://archive.org/download/xenial_python3.6_deb/python3.6-minimal_3.6.13-1%2Bxenial2_amd64.deb" )
RESOURCES+=( "https://dl.google.com/android/repository/platform-tools-latest-linux.zip" )
RESOURCES+=( "https://files.pythonhosted.org/packages/03/1a/60984cb85cc38c4ebdfca27b32a6df6f1914959d8790f5a349608c78be61/cryptography-1.5.2.tar.gz" )
RESOURCES+=( "https://files.pythonhosted.org/packages/10/46/059775dc8e50f722d205452bced4b3cc965d27e8c3389156acd3b1123ae3/pyasn1-0.4.4.tar.gz" )
RESOURCES+=( "https://files.pythonhosted.org/packages/16/d8/bc6316cf98419719bd59c91742194c111b6f2e85abac88e496adefaf7afe/six-1.11.0.tar.gz" )
RESOURCES+=( "https://files.pythonhosted.org/packages/34/a9/65ef401499e6878b3c67c473ecfd8803eacf274b03316ec8f2e86116708d/setuptools-11.3.tar.gz" )
RESOURCES+=( "https://files.pythonhosted.org/packages/65/c4/80f97e9c9628f3cac9b98bfca0402ede54e0563b56482e3e6e45c43c4935/idna-2.7.tar.gz" )
RESOURCES+=( "https://files.pythonhosted.org/packages/97/8d/77b8cedcfbf93676148518036c6b1ce7f8e14bf07e95d7fd4ddcb8cc052f/ipaddress-1.0.22.tar.gz" )
RESOURCES+=( "https://files.pythonhosted.org/packages/bf/3e/31d502c25302814a7c2f1d3959d2a3b3f78e509002ba91aea64993936876/enum34-1.1.6.tar.gz" )
RESOURCES+=( "https://files.pythonhosted.org/packages/e7/a7/4cd50e57cc6f436f1cc3a7e8fa700ff9b8b4d471620629074913e3735fb2/cffi-1.11.5.tar.gz" )
RESOURCES+=( "https://mirrors.edge.kernel.org/debian/pool/main/libj/libjpeg-turbo/libjpeg62-turbo_1.5.1-2_amd64.deb" )
RESOURCES+=( "https://mirrors.xtom.com/freebsd-pkg/FreeBSD:11:amd64/latest/All/open-vm-tools-nox11-11.3.0,2.pkg" )
RESOURCES+=( "https://raw.githubusercontent.com/curl/curl/85f91248cffb22d151d5983c32f0dbf6b1de572a/lib/mk-ca-bundle.pl" )
RESOURCES+=( "https://sourceware.org/pub/valgrind/valgrind-3.15.0.tar.bz2" )
RESOURCES+=( "https://storage.googleapis.com/git-repo-downloads/repo" )

# This server doesn't have a properly configured HTTPS certificate, so we use HTTP
RESOURCES+=( "http://archive.debian.org/debian/pool/main/o/openjdk-7/openjdk-7-jdk_7u181-2.6.14-1~deb8u1_amd64.deb" )
RESOURCES+=( "http://archive.debian.org/debian/pool/main/o/openjdk-7/openjdk-7-jre_7u181-2.6.14-1~deb8u1_amd64.deb" )
RESOURCES+=( "http://archive.debian.org/debian/pool/main/o/openjdk-7/openjdk-7-jre-headless_7u181-2.6.14-1~deb8u1_amd64.deb" )

# These files are used by the providers install script.
RESOURCES+=( "https://archive.org/download/vmwaretools10.1.15other6677369.tar/VMware-Tools-10.1.15-other-6677369.tar.gz" )
RESOURCES+=( "https://archive.org/download/vmware-workstation-17.0.0/VMware-Workstation-Full-15.5.7-17171714.x86_64.bundle" )
RESOURCES+=( "https://archive.org/download/vmware-workstation-17.0.0/VMware-Workstation-Full-16.2.5-20904516.x86_64.bundle" )
RESOURCES+=( "https://archive.org/download/vmware-workstation-17.0.0/VMware-Workstation-Full-17.0.0-20800274.x86_64.bundle" )

# If Vagrant is installed, use the newer version of curl.
if [ -f /opt/vagrant/embedded/bin/curl ]; then

  export CURL="/opt/vagrant/embedded/bin/curl"

  if [ -f /opt/vagrant/embedded/lib64/libssl.so ] && [ -z LD_PRELOAD ]; then
    export LD_PRELOAD="/opt/vagrant/embedded/lib64/libssl.so"
  elif [ -f /opt/vagrant/embedded/lib64/libssl.so ]; then
    export LD_PRELOAD="/opt/vagrant/embedded/lib64/libssl.so:$LD_PRELOAD"
  fi

  if [ -f /opt/vagrant/embedded/lib64/libcrypto.so ] && [ -z LD_PRELOAD ]; then
    export LD_PRELOAD="/opt/vagrant/embedded/lib64/libcrypto.so"
  elif [ -f /opt/vagrant/embedded/lib64/libcrypto.so ]; then
    export LD_PRELOAD="/opt/vagrant/embedded/lib64/libcrypto.so:$LD_PRELOAD"
  fi

  export LD_LIBRARY_PATH="/opt/vagrant/embedded/bin/lib/:/opt/vagrant/embedded/lib64/"

else
  export CURL="curl"
fi

function verify_logdir {

  if [ ! -d "$BASE/logs/" ]; then
    mkdir -p "$BASE/logs/" || mkdir "$BASE/logs"
  fi
}

# Build an individual box.
function box() {

  verify_logdir
  export PACKER_LOG="1"
  unset LD_PRELOAD ; unset LD_LIBRARY_PATH ;
  [ -z "$PACKER_ON_ERROR" ] && export PACKER_ON_ERROR="cleanup"

  if [[ "$(uname)" == "Linux" ]]; then

      export PACKER_LOG_PATH="$BASE/logs/altinity-libvirt-log-`date +'%Y%m%d.%H.%M.%S'`.txt"
      [[ "$1" =~ ^.*altinity.*$ ]] && [[ "$1" =~ ^.*libvirt.*$ ]] && packer build -on-error=$PACKER_ON_ERROR -parallel-builds=$PACKER_MAX_PROCS -only=$1 altinity-ubuntu2204-libvirt.json
  fi

  return 0
}

# Build a specific box.
if [[ $1 == "box" ]]; then box $2

# Catchall
else
  echo "Only supports `robox_altinity.sh box altinity-libvirt`"
  exit 2
fi
