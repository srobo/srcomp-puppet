node default {
    class { compbox:
        # Main user access is configured manually
        configure_main_user_access  => false,
        # main_user                 => 'root',
        manual_npm_installs         => false,
        # Note: you almost certainly want to change enable_tls to `false` on first-run
        enable_tls                  => true,
    }
}
