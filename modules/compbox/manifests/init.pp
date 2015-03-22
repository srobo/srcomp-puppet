# Install and configure the services running on the compbox
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

    exec { 'update package lists':
        command => '/usr/bin/apt-get update',
        before  => [Package['libyaml-dev'],Package['npm'],Package['nodejs']],
    }

    # A user for shelling in to update the compstate
    user { 'srcomp':
        ensure      => present,
        comment     => 'Competition Software Owner',
        gid         => 'users',
        managehome  => true,
        shell       => '/bin/bash',
    }

    $srcomp_home_dir = '/home/srcomp'
    $ref_compstate = "${srcomp_home_dir}/compstate.git"
    $srcomp_ssh_dir = "${srcomp_home_dir}/.ssh"

    file { $srcomp_ssh_dir:
        ensure  => directory,
        owner   => 'srcomp',
        group   => 'users',
        mode    => '0700',
        require => User['srcomp'],
    }

    file { "${srcomp_ssh_dir}/authorized_keys":
        ensure  => file,
        owner   => 'srcomp',
        group   => 'users',
        mode    => '0600',
        # TODO: this should probably end up in hiera
        source  => 'puppet:///modules/compbox/srcomp-authorized_keys',
        require => [User['srcomp'],File[$srcomp_ssh_dir]],
    }

    # A local srcomp-http checkout so we can use the update script.
    # It should probably get installed as a CLI endpoint at some point.
    $http_dir = "${srcomp_home_dir}/srcomp-http"
    vcsrepo { $http_dir:
        ensure   => present,
        provider => git,
        source   => "${comp_source}/comp/srcomp-http.git",
        user     => 'srcomp',
    }

    # The location of the live compstate.
    $compstate_dir = $compstate_path

    # The location of the 'virtualenv' in which the the srcomp things
    # are installed. Not really a virtualenv on this machine of course.
    $venv_dir = '/usr'

    # Update script, configured for direct use (via the above two variables)
    file { "${srcomp_home_dir}/update":
        ensure  => file,
        owner   => 'srcomp',
        group   => 'users',
        # Only this user can run it
        mode    => '0744',
        # Uses $compstate_dir, $http_dir, $venv_dir
        content => template('compbox/srcomp-update.erb'),
        require => [Vcsrepo[$http_dir],User['srcomp']],
    }

    vcsrepo { $ref_compstate:
        ensure    => bare,
        provider  => git,
        source    => $compstate,
        user      => 'srcomp',
        require   => User['srcomp'],
    }

    package { ['git',
               'python-setuptools',
               'python-dev',
               'python-requests']:
        ensure => present
    } ->
    # Ubuntu's system pip break as soon as sr.comp.cli is installed
    exec { 'install pip':
        command => '/usr/bin/easy_install pip',
        creates => '/usr/local/bin/pip'
    } ->
    package { 'sr.comp.ranker':
        ensure   => $vcs_ensure,
        provider => 'pip',
        source   => "git+${comp_source}/comp/ranker.git"
    } ->
    package { 'sr.comp':
        ensure   => $vcs_ensure,
        provider => 'pip',
        source   => "git+${comp_source}/comp/srcomp.git"
    } ->
    package { 'sr.comp.http':
        ensure   => $vcs_ensure,
        provider => 'pip',
        source   => "git+${comp_source}/comp/srcomp-http.git"
    }
    package { 'sr.comp.cli':
        ensure   => $vcs_ensure,
        provider => 'pip',
        source   => "git+${comp_source}/comp/srcomp-cli.git",
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
    } ->
    exec {
      'install bower':
        command => '/usr/bin/npm install -g bower --config.interactive=false',
        creates => '/usr/local/bin/bower';
      'install vulcanize':
        command => '/usr/bin/npm install -g vulcanize',
        creates => '/usr/local/bin/vulcanize';
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
    vcsrepo { '/var/www/screens':
        ensure   => $vcs_ensure,
        provider => git,
        source   => "${comp_source}/comp/srcomp-screens.git",
        owner    => 'www-data'
    } ~>
    exec { 'build screens':
        command     => '/usr/local/bin/bower install',
        cwd         => '/var/www/screens',
        environment => 'HOME=/var/www',
        refreshonly => true,
        user        => 'www-data',
        require     => Exec['install bower']
    } ~>
    exec { 'compile screens':
        command     => '/usr/bin/python /var/www/generate_screens.py',
        subscribe   => File['/var/www/generate_screens.py'],
        refreshonly => true,
        require     => [Package['python-lxml'],
                        File['/var/www/html'],
                        Exec['install vulcanize']],
        user        => 'www-data'
    }

    file { '/var/www/html':
        ensure  => directory,
        owner   => 'www-data',
        mode    => '0755',
        require => File['/var/www']
    } ->
    file { '/var/www/html/compbox-index.html':
        ensure  => file,
        source  => 'puppet:///modules/compbox/compbox-index.html',
        owner   => 'www-data',
    }

    package { 'python-lxml':
        ensure => present
    }

    file { '/var/www/generate_screens.py':
        ensure => file,
        source => 'puppet:///modules/compbox/generate_screens.py',
        owner  => 'www-data'
    }

    # Compstate
    vcsrepo { $compstate_path:
        ensure   => present,
        provider => git,
        source   => $ref_compstate,
        group    => 'www-data',
        owner    => 'srcomp',
        require  => [User['srcomp'],Vcsrepo[$ref_compstate]],
    }
    # Update trigger and lock files
    file { "${compstate_path}/.update-pls":
        ensure  => present,
        owner   => 'srcomp',
        group   => 'www-data',
        mode    => '0644',
        require => Vcsrepo[$compstate_path],
    }
    # The lock file is writable by apache so it can get a lock on it
    file { "${compstate_path}/.update-lock":
        ensure  => present,
        owner   => 'srcomp',
        group   => 'www-data',
        mode    => '0664',
        require => Vcsrepo[$compstate_path],
    }

    # Stream
    vcsrepo { '/var/www/stream':
        ensure   => $vcs_ensure,
        provider => git,
        source   => "${comp_source}/comp/srcomp-stream.git",
        owner    => 'www-data',
        require  => File['/var/www']
    } ~>
    exec { 'build stream':
        command     => '/usr/bin/npm install',
        cwd         => '/var/www/stream',
        user        => 'www-data',
        refreshonly => true,
        require     => Package['npm']
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
        require   => File['/usr/local/bin/node'],
        subscribe => [Exec['build stream'],
                      File['/var/www/stream/config.coffee'],
                      File['/etc/init.d/srcomp-stream'],
                      # Subscribe to the API to get config changes
                      Service['srcomp-api']]
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
        source   => 'https://github.com/PeterJCLaw/nwatchlive',
        owner    => 'www-data',
        require  => File['/var/www']
    } ~>
    exec { 'build nwatchlive':
        command     => '/usr/bin/npm install',
        cwd         => '/var/www/nwatchlive',
        user        => 'www-data',
        refreshonly => true,
        require     => Package['npm']
    }
    file { '/var/www/comp-services.js':
        ensure  => file,
        source  => 'puppet:///modules/compbox/comp-services.js',
        owner   => 'www-data',
        require => File['/var/www']
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

    # Login configuration
    file { '/home/vagrant/.ssh/authorized_keys':
        ensure  => file,
        mode    => '0600',
        owner   => 'vagrant',
        source  => 'puppet:///modules/compbox/vagrant-authorized_keys',
    }
    augeas { 'sshd_config':
        context => '/files/etc/ssh/sshd_config',
        changes => [
            # deny root logins
            'set PermitRootLogin no',
            # deny logins using passwords
            'set PasswordAuthentication no',
        ],
        notify  => Service['sshd'],
    }
    service { 'sshd':
        ensure  => running,
        name    => $::osfamily ? {
            Debian  => 'ssh',
            default => 'sshd',
        },
        enable  => true,
        require => Augeas['sshd_config'],
    }
}
