# Set the hostname on the Pis so that they can easily be identified when
# shelling in

class compbox::hostname ( $hostname = hiera('hostname') ) {

  if $::fqdn != $hostname {
    host { $::fqdn:
      ensure  => absent,
      before  => Exec['hostname.sh'],
    }

    if $::fqdn != $::hostname {
      host { $::hostname:
        ensure  => absent,
        before  => Exec['hostname.sh'],
      }
    }

    host { 'custom fqdn':
      ensure  => present,
      name    => $hostname,
      ip      => '127.0.1.1',
      before  => Exec['hostname.sh'],
    }

    file { '/etc/hostname':
      ensure  => present,
      owner   => 'root',
      group   => 'root',
      mode    => '0644',
      content => "${hostname}\n",
      notify  => Exec['hostname.sh'],
    }

    exec { 'hostname.sh':
      command     => '/etc/init.d/hostname.sh start',
      refreshonly => true,
    }
  }
}
