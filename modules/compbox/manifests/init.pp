class compbox {
    $comp_source    = 'git://studentrobotics.org'
    $compstate      = 'git://studentrobotics.org/comp/sr2015-comp.git'
    $compstate_path = '/srv/state'

    $track_source = false

    if $track_source {
      $vcs_ensure = 'latest'
    } else {
      $vcs_ensure = 'present'
    }

    package { ['git',
               'python-setuptools',
               'python-dev',
               'python-requests']:
        ensure => present
    } ->
    exec { 'install pip': # Ubuntu's system pip break as soon as sr.comp.cli is installed
        command => '/usr/bin/easy_install pip',
        creates => '/usr/local/bin/pip'
    } ->
    package { 'sr.comp.ranker':
        ensure   => $vcs_ensure,
        provider => 'pip',
        source   => "git+$comp_source/comp/ranker.git"
    } ->
    package { 'sr.comp':
        ensure   => $vcs_ensure,
        provider => 'pip',
        source   => "git+$comp_source/comp/srcomp.git"
    } ->
    package { 'sr.comp.http':
        ensure   => $vcs_ensure,
        provider => 'pip',
        source   => "git+$comp_source/comp/srcomp-http.git"
    }
    package { 'sr.comp.cli':
        ensure   => $vcs_ensure,
        provider => 'pip',
        source   => "git+$comp_source/comp/srcomp-cli.git",
        require  => Package['sr.comp']
    }

    # Yaml loading acceleration
    package { 'libyaml-dev':
        ensure => present,
        before => Package['sr.comp']
    }

    # Screens and stream
    package { ['nodejs', 'npm']:
        ensure => present
    } ~>
    exec { 'install bower':
        command => '/usr/bin/npm install -g bower --config.interactive=false',
        creates => '/usr/local/bin/bower'
    }

    # Fix Ubuntu's wacky node path
    file { '/usr/local/bin/node':
        ensure  => link,
        target  => '/usr/bin/nodejs',
        mode    => '0755',
        require => Package['nodejs'],
        before  => Exec['install bower']
    }

    # Main webserver
    package { 'nginx':
        ensure => present
    }

    # Screens
    file { '/var/www':
        ensure => directory,
        owner  => 'www-data',
        mode   => '0755'
    } ->
    vcsrepo { "/var/www/screens":
        ensure   => $vcs_ensure,
        provider => git,
        source   => "$comp_source/comp/srcomp-screens.git",
        owner    => 'www-data'
    } ~>
    exec { 'build screens':
        command     => '/usr/local/bin/bower install',
        cwd         => '/var/www/screens',
        creates     => '/var/www/screens/bower_components',
        environment => 'HOME=/var/www',
        user        => 'www-data',
        require     => Exec['install bower']
    }

    # Compstate
    vcsrepo { $compstate_path:
        ensure   => present,
        provider => git,
        source   => $compstate,
        owner    => 'www-data'
    }

    # Stream
    vcsrepo { "/var/www/stream":
        ensure   => $vcs_ensure,
        provider => git,
        source   => "$comp_source/comp/srcomp-stream.git",
        owner    => 'www-data',
        require  => File['/var/www']
    } ~>
    exec { 'build stream':
        command  => '/usr/bin/npm install',
        cwd      => '/var/www/stream',
        creates  => '/var/www/stream/node_modules',
        user     => 'www-data',
        require  => Package['npm']
    }
    file { '/var/www/stream/config.coffee':
        ensure  => file,
        source  => 'puppet:///modules/compbox/stream-config.coffee',
        owner   => 'www-data',
        require => VCSRepo['/var/www/stream']
    }
    file { '/etc/init.d/srcomp-stream':
        ensure => file,
        source => 'puppet:///modules/compbox/service-stream',
        mode   => '0755'
    }
    service { 'srcomp-stream':
        ensure    => running,
        subscribe => [Exec['build stream'],
                      File['/var/www/stream/config.coffee'],
                      File['/etc/init.d/srcomp-stream'],
                      Service['srcomp-api']] # Subscribe to the API to get config changes
    }

    # API
    package { 'gunicorn':
        ensure   => present,
        provider => 'pip',
        require  => Exec['install pip']
    }
    file { '/var/www/compapi.wsgi':
        ensure  => file,
        content => template('compbox/api-wsgi.cfg.erb'),
        require => File['/var/www']
    }
    file { '/etc/init.d/srcomp-api':
        ensure => file,
        source => 'puppet:///modules/compbox/service-api',
        mode   => '0755'
    }
    service { 'srcomp-api':
        ensure    => running,
        require   => [Package['gunicorn'],
                      VCSRepo[$compstate_path]],
        subscribe => [File['/var/www/compapi.wsgi'],
                      File['/etc/init.d/srcomp-api'],
                      Package['sr.comp.ranker'],
                      Package['sr.comp'],
                      Package['sr.comp.http']]
    }

    # nwatchlive
    vcsrepo { '/var/www/nwatchlive':
        ensure   => $vcs_ensure,
        provider => git,
        source   => 'https://github.com/prophile/nwatchlive',
        owner    => 'www-data',
        require  => File['/var/www']
    } ~>
    exec { 'build nwatchlive':
        command => '/usr/bin/npm install',
        cwd     => '/var/www/nwatchlive',
        creates => '/var/www/nwatchlive/node_modules',
        user    => 'www-data',
        require => Package['npm']
    }
    file { '/var/www/comp-services.js':
        ensure => file,
        source => 'puppet:///modules/compbox/comp-services.js',
        owner  => 'www-data'
    }
    file { '/etc/init.d/nwatchlive':
        ensure => file,
        source => 'puppet:///modules/compbox/service-nwatchlive',
        mode   => '0755'
    }
    service { 'nwatchlive':
        ensure    => running,
        require   => File['/usr/local/bin/node'],
        subscribe => [Exec['build nwatchlive'],
                      File['/var/www/comp-services.js'],
                      File['/etc/init.d/nwatchlive']]
    }

    # Nginx configuration
    file { '/etc/nginx/sites-enabled/default':
        ensure  => absent,
        require => Package['nginx'],
        notify  => Service['nginx']
    }

    file { '/etc/nginx/sites-enabled/compbox':
        ensure  => file,
        require => Package['nginx'],
        source  => 'puppet:///modules/compbox/nginx',
        notify  => Service['nginx']
    }

    service { 'nginx':
        ensure  => running,
        require => Package['nginx']
    }
}

