# vim: ft=puppet
user { $::app_user:
  ensure => present,
  groups => ["deploy"],
  home => "/home/${::app_user}"
}

file { "/home/${::app_user}":
  require => User[$::app_user],
  ensure => directory,
  mode => 0755,
  owner => $::app_user
}

file { "/etc/init/${::app_name}.conf":
  ensure => file,
  content => template("${::manifest_path}/upstart.conf.erb")
}

package { "monit":
  ensure => latest
}

service { "monit":
  ensure => running,
  enable => true,
  require => Package["monit"]
}

file { "/etc/monit/conf.d/${::app_name}.conf":
   ensure => file,
   content => template("${::manifest_path}/monit.conf.erb"),
   notify => Service["monit"]
}

file { $::app_path:
  mode => "g+w"
}

file { "${::app_path}/bin/${::app_name}":
  mode => 755
}

