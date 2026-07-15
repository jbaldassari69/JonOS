#!/usr/bin/env bash

set -u

printf '☕ Switching to the Work profile...\n'

if plasma-apply-lookandfeel --apply Mokka; then
    printf '✓ Mokka theme applied\n'
else
    printf '✗ Could not apply the Mokka theme\n' >&2
    exit 1
fi

printf '✓ Work profile ready\n'
