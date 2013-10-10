# vim: ft=puppet
package { "curl":
  ensure => installed
}

user { "gitlab-bridge":
  ensure => present,
  groups => ["deploy"]
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
  require => [Package["unzip"], Exec["download-play"]],
  cwd => "/opt",
  command => "/usr/bin/unzip play-2.2.0.zip",
  creates => "/opt/play-2.2.0"
}

file { "/opt/play":
  ensure => link,
  target => "/opt/play-2.2.0"
}

package { "default-jdk":
  ensure => installed
}

exec { "package-app":
  require => [Exec["unzip-play"], File["/opt/play"], Package["default-jdk"], User["gitlab-bridge"]],
  cwd => "${app_path}",
  command => "/opt/play/play clean compile stage",
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
