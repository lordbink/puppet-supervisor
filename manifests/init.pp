class supervisor {

  require pip

  pip::install { "supervisor": }

  service { "supervisord":
    ensure    => running,
    enable    => true,
    require   => [Pip::Install['supervisor'],
                  File['/etc/init.d/supervisord']],
    stop      => '/etc/init.d/supervisord stop',
    start     => '/etc/init.d/supervisord start',
    restart   => '/etc/init.d/supervisord restart',
    subscribe => File['/etc/supervisord.conf'],
  }

  case $operatingsystem {
    'debian': { $supervisord_conf = "puppet:///modules/supervisor/debian-isnok-initscript" }
    'ubuntu': { $supervisord_conf = "puppet:///modules/supervisor/ubuntu-initscript" }
    'redhat',
    'centos',
    'amazon': { $supervisord_conf = "puppet:///modules/supervisor/redhat-init-mingalevme"}
  }

  if ($operatingsystem == 'ubuntu') and ($lsbmajdisrelase >= '16.04') {
    file {'/lib/systemd/system/supervisor.service':
      source => 'puppet:///modules/supervisor/ubuntu-service',
      notify => Exec['daemon_reload']
    }
    exec { 'daemon_reload':
      command     => '/bin/systemctl daemon-reload',
      require     => File['/lib/systemd/system/supervisor.service'],
      user        => 'root',
      refreshonly => true,
    }
  }

  file { '/etc/init.d/supervisord':
    source  => $supervisord_conf,
    mode    => '0755',
  }

  file { '/etc/supervisor':
    ensure => directory,
  }

  file { '/etc/supervisord.conf':
    source  => 'puppet:///modules/supervisor/supervisord.conf',
    require => File['/etc/supervisor'],
  }

  file { '/etc/supervisor/conf.d/':
    ensure  => directory,
    recurse => true,
    purge   => true,
    notify  => Service['supervisord'],
    require => File['/etc/supervisor'],
  }
}
