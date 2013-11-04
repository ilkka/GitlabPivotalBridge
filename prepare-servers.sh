#!/bin/bash
# Prepare server(s) for deployment
set -e

HOSTS=()

while  (( "$#" )); do
  HOSTS+=("$1")
  shift
done

for HOST in $HOSTS; do
  echo "Preparing $HOST"
  scp $HOME/.ssh/id_rsa.pub $HOST:/tmp/deploy-pubkey
  ssh $HOST "which puppet" || ssh -t $HOST "cd /tmp && wget http://apt.puppetlabs.com/puppetlabs-release-precise.deb && sudo dpkg -i puppetlabs-release-precise.deb && sudo apt-get update && sudo env DEBIAN_FRONTEND=noninteractive apt-get install -y puppet"
  ssh $HOST "cat > /tmp/prepare-server.pp" <<EOF
package { "git":
  ensure => latest,
}
user { "deploy":
  ensure => present,
  home => "/home/deploy"
}
file { "/home/deploy":
  require => User["deploy"],
  ensure => directory,
  mode => 0755,
  owner => "deploy"
}
file { "/home/deploy/.ssh":
  ensure => directory,
  mode => 0700,
  owner => "deploy"
}
file { "/home/deploy/.ssh/authorized_keys":
  ensure => file,
  owner => "deploy"
}
exec { "add-pubkey":
  require => File["/home/deploy/.ssh/authorized_keys"],
  cwd => "/home/deploy",
  user => "deploy",
  path => ["/usr/local/sbin", "/usr/local/bin", "/usr/sbin", "/usr/bin", "/sbin", "/bin"],
  command => "cat /tmp/deploy-pubkey >> .ssh/authorized_keys"
}
file { "/etc/sudoers.d/deploy-user-can-restart-services":
  ensure => present,
  mode => 0440,
  owner => "root",
  group => "root",
  content => "deploy ALL = (ALL:ALL) NOPASSWD: SETENV: /usr/bin/puppet, /sbin/start, /sbin/stop, /sbin/restart\n"
}
file { "/opt":
  require => User["deploy"],
  ensure => directory,
  mode => "u+rwx,g+rwxs,o+rx",
  group => "deploy"
}
EOF
  ssh -t $HOST "sudo puppet apply /tmp/prepare-server.pp"
  echo "$HOST ready for deployment"
done
