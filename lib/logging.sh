#!/usr/bin/env bash

log() {
    printf '[JonOS] %s\n' "$*"
}

error() {
    printf '[JonOS] ERROR: %s\n' "$*" >&2
}
