#!/usr/bin/env bash

set -u

printf '🌙 Switching to the Coding profile...\n'

if plasma-apply-lookandfeel --apply org.kde.breezedark.desktop; then
    printf '✓ Breeze Dark applied\n'
else
    printf '✗ Could not apply Breeze Dark\n' >&2
    exit 1
fi

for app in konsole code; do
    if command -v "$app" >/dev/null 2>&1; then
        if ! pgrep -x "$app" >/dev/null 2>&1; then
            "$app" >/dev/null 2>&1 &
            printf '✓ Started %s\n' "$app"
        else
            printf '• %s is already running\n' "$app"
        fi
    else
        printf '• %s is not installed\n' "$app"
    fi
done

printf '✓ Coding profile ready\n'
