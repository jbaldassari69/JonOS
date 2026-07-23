#!/usr/bin/env bash

set -Eeuo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
DRY_RUN=false

log() {
    printf '[JonOS] %s\n' "$*"
}

error() {
    printf '[JonOS] ERROR: %s\n' "$*" >&2
}

usage() {
    cat <<'EOF'
Usage: bootstrap.sh [OPTIONS]

Options:
  --dry-run   Show what JonOS would do without making changes
  -h, --help  Show this help message
EOF
}

detect_distribution() {
    if [[ ! -r /etc/os-release ]]; then
        error "Unable to read /etc/os-release"
        return 1
    fi

    # shellcheck disable=SC1091
    source /etc/os-release

    DISTRO_ID="${ID:-unknown}"
    DISTRO_NAME="${PRETTY_NAME:-$DISTRO_ID}"
    DISTRO_LIKE="${ID_LIKE:-}"
}

parse_arguments() {
    while (($#)); do
        case "$1" in
            --dry-run)
                DRY_RUN=true
                ;;
            -h|--help)
                usage
                exit 0
                ;;
            *)
                error "Unknown option: $1"
                usage
                exit 2
                ;;
        esac
        shift
    done
}

main() {
    parse_arguments "$@"
    detect_distribution

    log "JonOS bootstrap starting"
    log "Project directory: $SCRIPT_DIR"
    log "Detected platform: $DISTRO_NAME"

    if [[ -n "$DISTRO_LIKE" ]]; then
        log "Distribution family: $DISTRO_LIKE"
    fi

    if [[ "$DRY_RUN" == true ]]; then
        log "Dry-run mode enabled; no changes will be made"
    fi

    log "Bootstrap foundation check complete"
}

main "$@"
