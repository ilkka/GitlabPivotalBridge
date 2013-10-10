# vim: ft=puppet
package { "curl":
  ensure => installed
}

user { "gitlab-bridge":
  ensure => present,
  groups => ["deploy"],
  home => "/home/gitlab-bridge"
}

file { "/home/gitlab-bridge",
  require => User["gitlab-bridge"],
  ensure => directory,
  mode => 0755,
  owner => "gitlab-bridge"
}

exec { "download-play":
  require => [Package["curl"]],
  cwd => "/opt",
  command => "/usr/bin/curl -O http://downloads.typesafe.com/play/2.2.0/play-2.2.0.zip",
  creates => "/opt/play-2.2.0.zip"
}

package { "unzip":
  ensure => installed
}

exec { "unzip-play": 
  require => [Package["unzip"], Exec["download-play"], User["gitlab-bridge"]],
  user => "gitlab-bridge",
  cwd => "/home/gitlab-bridge",
  command => "/usr/bin/unzip play-2.2.0.zip",
  creates => "/home/gitlab-bridge/play-2.2.0"
}

file { "/home/gitlab-bridge/play":
  ensure => link,
  target => "/home/gitlab-bridge/play-2.2.0"
}

package { "default-jdk":
  ensure => installed
}

exec { "package-app":
  require => [Exec["unzip-play"], File["/home/gitlab-bridge/play"], Package["default-jdk"]],
  cwd => "${app_path}",
  command => "/home/gitlab-bridge/play/play clean compile stage",
  user => "gitlab-bridge"
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
