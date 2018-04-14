#!/bin/bash

sudo apt-get install --yes puppet git

git submodule update --init --recursive

exec ./apply-puppet.sh
