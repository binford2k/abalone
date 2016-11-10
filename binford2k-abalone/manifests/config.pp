class abalone::config {
  # pull these into local scope so we can use them in templates
  $port        = $abalone::port
  $bind        = $abalone::bind
  $method      = $abalone::method
  $bannerfile  = $abalone::bannerfile
  $logfile     = $abalone::logfile
  $ssh_host    = $abalone::ssh_host
  $ssh_cert    = $abalone::ssh_cert
  $ssh_port    = $abalone::ssh_port
  $ssh_user    = $abalone::ssh_user
  $command     = $abalone::command
  $params      = $abalone::params
  $uuid        = $abalone::uuid

  File {
    owner  => 'root',
    group  => 'root',
    mode   => '0644',
  }

  file { $logfile:
    ensure => file,
  }

  file { '/etc/abalone':
    ensure  => directory,
  }

  file { '/etc/abalone/config.yaml':
    ensure  => file,
    content => template('abalone/config.yaml.erb'),
  }

  file { "/usr/lib/systemd/system/abalone.service":
    ensure  => file,
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    content => file('abalone/abalone.service'),
    before  => Service['abalone'],
  }

}
