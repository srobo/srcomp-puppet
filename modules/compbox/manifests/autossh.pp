class compbox::autossh {
    user { 'autossh':
        ensure      => present,
        comment     => 'A user for port forwarding',
        gid         => 'users',
        managehome  => true,
        shell       => '/usr/sbin/nologin',
    }

    $home_dir = '/home/autossh'
    $ssh_dir = "${home_dir}/.ssh"

    file { $ssh_dir:
        ensure  => directory,
        owner   => 'autossh',
        group   => 'users',
        mode    => '0700',
        require => User['autossh'],
    }

    file { "${ssh_dir}/authorized_keys":
        ensure  => file,
        owner   => 'autossh',
        group   => 'users',
        mode    => '0600',
        # TODO: this should probably end up in hiera
        source  => 'puppet:///modules/compbox/autossh-authorized_keys',
        require => [User['autossh'],File[$ssh_dir]],
    }
}
