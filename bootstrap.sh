#!/usr/bin/env bash

set -Eeuo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/context.sh"
source "$SCRIPT_DIR/lib/logging.sh"
source "$SCRIPT_DIR/lib/args.sh"
source "$SCRIPT_DIR/lib/distro.sh"
source "$SCRIPT_DIR/lib/packages.sh"
source "$SCRIPT_DIR/lib/install.sh"

usage() {
    cat <<'EOF'
Usage: bootstrap.sh [OPTIONS]

Options:
  --dry-run   Show what JonOS would do without making changes
  --install   Install missing packages
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
            --install)
                INSTALL_MODE=true
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

    if [[ "$DRY_RUN" == true && "$INSTALL_MODE" == true ]]; then
        error "--dry-run and --install cannot be used together"
        exit 2
    fi

    if [[ "$DRY_RUN" == true ]]; then
        log "Dry-run mode enabled; no changes will be made"
    elif [[ "$INSTALL_MODE" == true ]]; then
        log "Install mode enabled"
    fi
}

install_missing_arch_packages() {
    if ((${#MISSING_PACKAGES[@]} == 0)); then
        log "All required packages are already installed"
        return 0
    fi

    if [[ "$DRY_RUN" == true ]]; then
        log "Dry-run: would install ${#MISSING_PACKAGES[@]} package(s)"
        printf '  - %s\n' "${MISSING_PACKAGES[@]}"
        return 0
    fi

    if [[ "$INSTALL_MODE" != true ]]; then
        log "Installation not requested; no changes made"
        return 0
    fi

    log "Installing ${#MISSING_PACKAGES[@]} missing package(s)"

    sudo pacman -S --needed "${MISSING_PACKAGES[@]}"
}

main() {
    parse_arguments "$@"

    detect_distribution
    show_distribution

    display_package_manifests
    validate_packages
    check_packages
    show_package_summary
    install_missing_arch_packages
    install_missing_arch_packages

    log "Bootstrap foundation complete"
}
main "$@"
