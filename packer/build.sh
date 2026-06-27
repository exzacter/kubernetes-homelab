#!/bin/bash
set -euo pipefail

cd "$(dirname "$0")"

if ! command -v packer &>/dev/null; then
    echo "packer not found"
    exit 1
fi

if [ ! -f "secrets.pkrvars.hcl" ]; then
    echo "secrets.pkrvars.hcl not found"
    exit 1
fi

NODE="${1:-}"

packer init ubuntu-2404.pkr.hcl

if [ -n "$NODE" ]; then
    packer build -force -on-error=ask \
        -var-file=variables.pkrvars.hcl \
        -var-file=secrets.pkrvars.hcl \
        -var="proxmox_node=$NODE" \
        ubuntu-2404.pkr.hcl
else
    packer build -force -on-error=ask \
        -var-file=variables.pkrvars.hcl \
        -var-file=secrets.pkrvars.hcl \
        ubuntu-2404.pkr.hcl
fi
