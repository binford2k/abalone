class abalone (
  $port        = $abalone::params::port,
  $bind        = $abalone::params::bind,
  $method      = $abalone::params::method,
  $path        = $abalone::params::path,
  $bannerfile  = $abalone::params::bannerfile,
  $logfile     = $abalone::params::logfile,
  $ssh_host    = $abalone::params::ssh_host,
  $ssh_cert    = $abalone::params::ssh_cert,
  $ssh_port    = $abalone::params::ssh_port,
  $ssh_user    = $abalone::params::ssh_user,
  $command     = $abalone::params::command,
  $params      = $abalone::params::params,
  $uuid        = $abalone::params::uuid,
) inherits abalone::params {
  # TODO: parameter validation

  case $method {
    'login': {
      if $ssh_host {
        fail('The login method and the ssh settings are exclusive')
      }
      if $command {
        fail('The login method and a custom command are exclusive')
      }
    }
    'ssh': {
      if $command {
        fail('The ssh method and a custom command are exclusive')
      }
    }
    'command': {
      if $ssh_host {
        fail('A custom command and the ssh settings are exclusive')
      }
    }
  }

  package { 'abalone':
    ensure   => present,
    provider => gem,
    before   => Service['abalone'],
  }

  include abalone::config

  service { 'abalone':
    ensure => running,
    enable => true,
    subscribe => Class['abalone::config'],
  }
}
