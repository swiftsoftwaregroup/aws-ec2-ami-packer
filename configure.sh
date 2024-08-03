#!/usr/bin/env bash

# get script dir
script_dir=$( cd `dirname ${BASH_SOURCE[0]}` >/dev/null 2>&1 ; pwd -P )

pushd $script_dir > /dev/null

# Packer
echo "Packer ..." 

packer init .

popd > /dev/null
