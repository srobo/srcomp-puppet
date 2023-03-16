node default {
    class { compbox:
        # Main user access is configured manually
        configure_main_user_access  => false,
        # main_user                 => 'root',
        manual_npm_installs         => false,
        enable_tls                  => true,
    }
}
