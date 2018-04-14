#!/bin/sh

MY_DIR=$(dirname $0)

if [ -n "$1" ]
then
    MANIFEST="$1"
else
    if [ "pi" = "$USER" ]
    then
        MANIFEST="$MY_DIR/manifests/raspberry-pi.pp"
    else
        MANIFEST="$MY_DIR/manifests/public.pp"
    fi
    echo "Running $MANIFEST based on platform"
fi

exec sudo puppet apply --modulepath=$MY_DIR/modules $MANIFEST
