#!/bin/bash
# Prepare server(s) for deployment
set -e

function has_puppet {
  local HOST=$1
  ssh $HOST "which puppet" > /dev/null
}

function install_puppet {
  local HOST=$1
  local SUDOPASS=$2
  echo $SUDOPASS | ssh $HOST "cd /tmp && wget http://apt.puppetlabs.com/puppetlabs-release-precise.deb && sudo -p '' dpkg -i puppetlabs-release-precise.deb && sudo apt-get update && sudo env DEBIAN_FRONTEND=noninteractive apt-get install -y puppet"
}

function has_git {
  local HOST=$1
  ssh $HOST "which git" > /dev/null
}

function install_git {
  local HOST=$1
  local SUDOPASS=$2
  echo $SUDOPASS | ssh $HOST "sudo -p '' env DEBIAN_FRONTEND=noninteractive apt-get install -y git"
}

function has_deploy_user {
  local HOST=$1
  ssh $HOST "grep -q deploy /etc/passwd"
}

function create_deploy_user {
  local HOST=$1
  local SUDOPASS=$2
  echo $SUDOPASS | ssh $HOST "sudo -p '' adduser --disabled-password --gecos deploy,,, deploy"
}

function can_ssh_as_deploy_user {
  local HOST=$1
  ssh -i $HOME/.ssh/id_rsa deploy@$HOST true
}

function add_ssh_key {
  local HOST=$1
  local SUDOPASS=$2
  (echo $SUDOPASS; cat $HOME/.ssh/id_rsa.pub) | ssh $HOST "sudo -p '' mkdir -p /home/deploy/.ssh && sudo chown deploy:deploy /home/deploy/.ssh && sudo chmod 700 /home/deploy/.ssh && sudo tee /home/deploy/.ssh/authorized_keys"
}

function has_sudoers_line {
  local HOST=$1
  local SUDOPASS=$2
  echo $SUDOPASS | ssh $HOST "sudo -p '' grep -q deploy-setup-tag /etc/sudoers"
}

function add_sudoers_line {
  local HOST=$1
  local SUDOPASS=$2
  echo $SUDOPASS | ssh $HOST "sudo -p '' cp /etc/sudoers /tmp/sudoers.tmp && echo '# Automatically added, do not edit. deploy-setup-tag'|sudo tee -a /tmp/sudoers.tmp && echo 'deploy ALL = (ALL:ALL) NOPASSWD: SETENV: /usr/bin/puppet, /sbin/start, /sbin/stop, /sbin/restart'|sudo tee -a /tmp/sudoers.tmp && sudo visudo -cf /tmp/sudoers.tmp && sudo cp /etc/sudoers /etc/sudoers.bak && sudo mv /tmp/sudoers.tmp /etc/sudoers"
}

function is_opt_writable {
  local HOST=$1
  local SUDOPASS=$2
  echo $SUDOPASS | ssh $HOST "sudo -p '' su deploy -c 'touch /opt/.deploy-can-write' && sudo rm /opt/.deploy-can-write"
}

function make_opt_writable {
  local HOST=$1
  local SUDOPASS=$2
  echo $SUDOPASS | ssh $HOST "sudo -p '' chgrp deploy /opt && sudo chmod g+rwxs /opt"
}

HOSTS=()

while  (( "$#" )); do
  HOSTS+=("$1")
  shift
done

for HOST in $HOSTS; do
  echo "Preparing $HOST"
  sudopass=""
  read -s -p "sudo password for $HOST:" sudopass
  echo
  if ! has_puppet $HOST > /dev/null; then
    echo "Installing puppet on $HOST from apt.puppetlabs.com"
    install_puppet $HOST $sudopass > /dev/null
  fi
  if ! has_git $HOST > /dev/null; then
    echo "Installing git on $HOST"
    install_git $HOST $sudopass > /dev/null
  fi
  if ! has_deploy_user $HOST > /dev/null; then
    echo "Creating deploy user on $HOST"
    create_deploy_user $HOST $sudopass > /dev/null
  fi
  if ! can_ssh_as_deploy_user $HOST > /dev/null; then
    echo "Adding $HOME/.ssh/id_rsa.pub to authorized_keys for deploy user on $HOST"
    add_ssh_key $HOST $sudopass > /dev/null
  fi
  if ! has_sudoers_line $HOST $sudopass > /dev/null; then
    echo "Adding sudoers line for deploy user on $HOST"
    add_sudoers_line $HOST $sudopass > /dev/null
  fi
  if ! is_opt_writable $HOST > /dev/null; then
    echo "Making /opt writable for deploy"
    make_opt_writable $HOST $sudopass > /dev/null
  fi
  echo "$HOST ready for deployment"
done
