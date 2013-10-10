# vim: ft=puppet
package { "curl":
  ensure => installed
}

user { "gitlab-bridge":
  ensure => present
}

exec { "download-play":
  require => [Package["curl"], User["gitlab-bridge"]],
  cwd => "/home/gitlab-bridge",
  command => "/usr/bin/curl -O http://downloads.typesafe.com/play/2.2.0/play-2.2.0.zip",
  creates => "/home/gitlab-bridge/play-2.2.0.zip",
  user => "gitlab-bridge"
}

package { "unzip":
  ensure => installed
}

exec { "unzip-play": 
  require => [Package["unzip"], Exec["download-play"]],
  cwd => "/home/gitlab-bridge",
  command => "/usr/bin/unzip play-2.2.0.zip",
  creates => "/home/gitlab-bridge/play-2.2.0",
  user => "gitlab-bridge"
}

file { "/home/gitlab-bridge/play":
  ensure => link,
  target => "/home/gitlab-bridge/play-2.2.0"
}

exec { "add-play-to-path":
  require => File["/home/gitlab-bridge-play"],
  cwd => "/home/gitlab-bridge",
  command => "echo 'export PATH=$HOME/play:$PATH # gl-play-path-setup' >> .bashrc",
  unless => "grep -q gl-play-path-setup .bashrc"
}

file { "/etc/init/gitlabpivotalbridge.conf":
  ensure => file,
  content => template("${app_path}/manifests/upstart.conf.erb")
}

package { "monit":
  ensure => latest
}

service { "monit":
  ensure => running,
  enable => true,
  require => Package["monit"]
}

file { "/etc/monit/conf.d/gitlabpivotalbridge.conf":
   ensure => file,
   content => template("${app_path}/manifests/monit.conf.erb"),
   notify => Service["monit"]
}
