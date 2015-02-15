class compbox {
    $comp_source = 'git+git://studentrobotics.org'
    $comp_user = 'vagrant'

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
        ensure   => latest,
        provider => 'pip',
        source   => "$comp_source/comp/ranker.git"
    } ->
    package { 'sr.comp':
        ensure   => latest,
        provider => 'pip',
        source   => "$comp_source/comp/srcomp.git"
    } ->
    package { 'sr.comp.http':
        ensure   => latest,
        provider => 'pip',
        source   => "$comp_source/comp/srcomp-http.git"
    }
    package { 'sr.comp.cli':
        ensure   => latest,
        provider => 'pip',
        source   => "$comp_source/comp/srcomp-cli.git",
        require  => Package['sr.comp']
    }
    package { 'gunicorn':
        ensure   => present,
        provider => 'pip',
        require  => Exec['install pip']
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
        ensure   => latest,
        provider => git,
        source   => "git://studentrobotics.org/comp/srcomp-screens.git",
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

