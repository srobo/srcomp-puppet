#!/bin/bash

if [[ $UID != 0 ]]
then
    echo "Must be run as root!"
    exec sudo $0
fi

mydir=`dirname $0`
cd $mydir
mydir=$PWD

puppet_dir='/etc/puppet'

if [[ -d $puppet_dir ]]
then
    echo -n "Puppet dir ($puppet_dir) already exists, remove it? [y/N]: "
    read do_remove
    if [[ $do_remove = "y" ]]
    then
        rm -rf $puppet_dir
    else
        exit 1
    fi
fi

git submodule update --init --recursive

ln -s $mydir $puppet_dir

apt-get install puppet

./deploy.sh
