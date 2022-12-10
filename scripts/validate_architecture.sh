#!/usr/bin/env bash

# If docker info fails, then this should also fail
set -e

if [[ $# != 1 ]]; then
    echo "usage: $BASH_SOURCE [arch]"
    exit 1
fi

arch="$(docker info -f '{{.Architecture}}')"

# Convert between equivalent aliases
if [[ "$arch" == "x86_64" ]]; then
    arch="amd64"
fi

if [[ "$arch" != "$1" ]]; then
    echo -e "\033[1;31mMismatch between provided architecture \"$1\"" \
            "and actual architecture \"$arch\"\033[0m"
    exit 1
else
    echo "architecture ok"
    exit 0
fi
