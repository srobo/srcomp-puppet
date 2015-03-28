# SRCompBox 2015

This is the configuration for the SR 2015 Competition VM.

It's a lightweight Vagrant wrapper around a puppet config.

Note: to simplify deployment on the day, the default Vagrant logins are
disabled by the puppet run. If you want to be able to access the machine
you create then you should add one of the public keys for the private
keys specified in `config.ssh.private_key_path` to
 `modules/compbox/files/vagrant-authorized_keys`.

Once the machine is up and running, you should be able to see the pages
it serves via <http://localhost:8080> and there is a test script which
will validate them: `./check-pages.py`.

## Setup Notes

At the test day we had an issue where even after enabling `public_network`
mode the VM still wasn't visible outside the host as it didn't get an IPv4
address for reasons unknown. This was solved on the test day by using
<https://github.com/vinodpandey/python-port-forward> to do port forwarding
on the host machine, and then just hitting the host instead of the VM
directly, which may well be a suitable solution if needed.
