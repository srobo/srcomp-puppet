$configure_main_user_access = true
$main_user = 'pi'
$manual_npm_installs = true
$enable_tls = false

node default {
    include compbox

    class { 'compbox::hostname':
        hostname    => 'compbox-2019.srobo',
    }
}
