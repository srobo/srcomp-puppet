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
        command     => '/usr/bin/npm install -g bower',
        refreshonly => true
    }

    # Main webserver
    package { 'nginx':
        ensure => present
    }
}

