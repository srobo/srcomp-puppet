$configure_main_user_access = true
$main_user = 'pi'

node default {
    include compbox

    class { 'hostname':
        hostname    => 'compbox-2018.sr',
    }
}
