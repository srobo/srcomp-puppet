# SRComp Puppet

This is a [puppet][puppet] configuration for various [SRComp][srcomp] related
things, including the creation of a VM suitable for use at a competition event.

[puppet]: https://github.com/puppetlabs/puppet
[srcomp]: https://github.com/PeterJCLaw/srcomp

In particular, this configures the hosting of:
 * [SRComp HTTP](https://github.com/PeterJCLaw/srcomp-http)
 * [SRComp Stream](https://github.com/PeterJCLaw/srcomp-stream)
 * [SRComp Screens](https://github.com/PeterJCLaw/srcomp-screens)
 * An index page which links to the hosted services

An `srcomp` user is created which has access to update the compstate deployed
within the machine; this user is a suitable target for the
[`srcomp deploy`][srcomp-deploy] command (and its siblings). Access to this user
over SSH is granted by adding public keys to
`modules/compbox/files/srcomp-authorized_keys`.

[srcomp-deploy]: https://github.com/PeterJCLaw/srcomp/wiki/Common-Operations#deploying-changes

## Development

A `Vagrantfile` and top-level manifest are provided for local development using
[Vagrant][vagrant]. This creates an Ubuntu based VM with port 80 forwarded to
port 8080 on the host machine. Visiting <http://localhost:8080> on the host
should show a compbox welcome page once the VM is provisioned.

Note: since deployment of the vagrant box is a supported (but discouraged)
scenario, the Vagrantfile compensates for the removal of the insecure vagrant
public key SSH access by expecting that `config.ssh.private_key_path` will
include a private key whose public key has been added to
`modules/compbox/files/main-user-authorized_keys`.

[vagrant]: https://vagrantup.com/

## Deployment

Deployment is supported via three mechanisms:

 * to a VM ([setup instructions](./new-machine.md))
 * under vagrant (note: this is discouraged)
 * using a Raspberry Pi

Note that the default (insecure) credential-based access over ssh to the default
user (as well as `root`) are disabled. For the VM setup you should configure
your own admin account (the instructions guide doing this). For other two cases,
access to the main user is available via SSH using keys whose public keys are in
`modules/compbox/files/main-user-authorized_keys`.

However you run it, the compbox will provide the following services. These will
all be [allowed through its firewall](modules/compbox/manifests/firewall.pp),
though if you are going to put it behind a proxy of any kind you'll need to
ensure access to all of these is available:

 * `SSH` (needed for compstate deployment)
 * `NTP` (to keep the screens clocks in sync)
 * `HTTPS` (for the API, stream and hosted pages)

Note that, for the hosted VM case only, TLS is automatically configured via
Let's Encrypt. As a result in general there should be no need to put the compbox
behind a proxy. However such configurations do therefore also need insecure
`HTTP` access (which is used to bootstrap the HTTPS configuration).

The default state of a fresh machine is configured around the dummy compstate.
Therefore the first time you deploy your own compstate you may get a warning
that the compstate being deployed isn't related to the current deployment. This
is obviously expected on your first deploy, but should be carefully regarded
thereafter.

## Validation

No attempt is made to test the puppet configuration directly. Instead, running
instances can be validated using `scripts/check-pages.py`. This downloads the
index page from the compbox and validates that all the pages which that links to
are accessible.

Note: this does not validate `SSH` or `NTP` access.

## Updates

Once deployed it is possible to update a deployment using:

``` shell
/etc/puppet/scripts/update
```

## Setup Notes

At the test day we had an issue where even after enabling `public_network`
mode the VM still wasn't visible outside the host as it didn't get an IPv4
address for reasons unknown. This was solved on the test day by using
<https://github.com/vinodpandey/python-port-forward> to do port forwarding
on the host machine, and then just hitting the host instead of the VM
directly, which may well be a suitable solution if needed.
