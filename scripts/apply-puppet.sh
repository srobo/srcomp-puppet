#!/bin/sh

cd $(dirname $0)/..

if [ -f "$1" ]
then
    MANIFEST="$1"
    shift
else
    if [ "pi" = "$USER" ]
    then
        MANIFEST="manifests/raspberry-pi.pp"
    else
        MANIFEST="manifests/public.pp"
    fi
    echo "Running $MANIFEST based on platform"
fi

exec sudo puppet apply --modulepath=modules $MANIFEST "$@"
