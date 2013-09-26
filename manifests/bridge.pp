# vim: ft=puppet
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
