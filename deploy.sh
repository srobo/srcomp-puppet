#!/bin/bash

if [[ ! -d "/etc/puppet" ]]
then
    echo "Puppet dir not present; cannot deploy. Did you run init yet?"
    exit 1
fi

if [[ $UID != 0 ]]
then
    echo "Must be run as root!"
    exec sudo $0
fi

puppet apply /etc/puppet/manifests/default.pp
