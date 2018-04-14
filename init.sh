#!/bin/bash

if [[ $UID != 0 ]]
then
    echo "Must be run as root!"
    exec sudo $0
fi

apt-get install --yes puppet git

git submodule update --init --recursive

exec ./apply-puppet.sh
