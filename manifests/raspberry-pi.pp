$configure_main_user_access = true
$main_user = 'pi'
$manual_npm_installs = true

node default {
    include compbox

    class { 'compbox::hostname':
        hostname    => 'compbox-2019.srobo',
    }
}
