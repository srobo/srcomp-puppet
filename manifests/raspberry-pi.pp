node default {
    class { compbox:
        configure_main_user_access  => true,
        main_user                   => 'pi',
        manual_npm_installs         => true,
        enable_tls                  => false,
    }

    class { 'compbox::hostname':
        hostname    => 'compbox.sr',
    }
}
