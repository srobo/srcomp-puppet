#!/bin/sh

cd $(dirname $0)/..

if [ -n "$1" ]
then
    MANIFEST="$1"
else
    if [ "pi" = "$USER" ]
    then
        MANIFEST="manifests/raspberry-pi.pp"
    else
        MANIFEST="manifests/public.pp"
    fi
    echo "Running $MANIFEST based on platform"
fi

exec sudo puppet apply --modulepath=modules $MANIFEST
