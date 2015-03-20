Vagrant.configure("2") do |config|
    config.vm.box = "compbox-ubuntu-1410"
    config.vm.box_url = "https://cloud-images.ubuntu.com/vagrant/utopic/current/utopic-server-cloudimg-amd64-vagrant-disk1.box"

    config.vm.network "forwarded_port", guest: 80, host: 8080

    config.vm.provision "puppet" do |puppet|
        puppet.manifests_path = "manifests"
        puppet.manifest_file  = "default.pp"
        puppet.module_path    = "modules"
    end
end
