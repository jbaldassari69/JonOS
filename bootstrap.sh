#!/usr/bin/env bash

set -Eeuo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
DRY_RUN=false

INSTALLED_PACKAGES=()
MISSING_PACKAGES=()

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

read_manifest() {
    local manifest="$1"

    if [[ ! -f "$manifest" ]]; then
        error "Package manifest not found: $manifest"
        return 1
    fi

    grep -Ev '^[[:space:]]*(#|$)' "$manifest"
}

show_packages() {
    local manifest="$1"
    local label="$2"
    local packages=()

    mapfile -t packages < <(read_manifest "$manifest")

    log "$label packages: ${#packages[@]}"

    for package in "${packages[@]}"; do
        printf '  - %s\n' "$package"
    done
validate_arch_packages() {
    local manifest="$1"
    local package
    local invalid=0

    while IFS= read -r package; do
        [[ -z "$package" ]] && continue

        if pacman -Si "$package" >/dev/null 2>&1; then
            log "Valid package: $package"
        else
            error "Package not found in configured repositories: $package"
            invalid=1
        fi
    done < <(read_manifest "$manifest")

    return "$invalid"
}
}
check_installed_arch_packages() {
    local manifest="$1"
    local package

    while IFS= read -r package; do
        [[ -z "$package" ]] && continue

        if pacman -Q "$package" >/dev/null 2>&1; then
            INSTALLED_PACKAGES+=("$package")
            printf '  [installed] %s\n' "$package"
        else
            MISSING_PACKAGES+=("$package")
            printf '  [missing]   %s\n' "$package"
        fi
    done < <(read_manifest "$manifest")
    show_package_summary() {
    printf '\n'
    log "Package summary"
    printf '  Installed: %d\n' "${#INSTALLED_PACKAGES[@]}"
    printf '  Missing:   %d\n' "${#MISSING_PACKAGES[@]}"

    if (( ${#MISSING_PACKAGES[@]} > 0 )); then
        printf '\n'
        log "Packages requiring installation"

        local package
        for package in "${MISSING_PACKAGES[@]}"; do
            printf '  - %s\n' "$package"
        done
    fi
}
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

    show_packages "$SCRIPT_DIR/packages/common.txt" "Common"

    if [[ "$DISTRO_ID" == "arch" || "$DISTRO_LIKE" == *"arch"* ]]; then
        show_packages "$SCRIPT_DIR/packages/arch.txt" "Arch family"
    fi
    if [[ "$DRY_RUN" == true ]]; then
    log "Dry-run mode enabled; no changes will be made"
    fi

    if [[ "$DISTRO_ID" == "arch" || "$DISTRO_LIKE" == *"arch"* ]]; then
    log "Validating Arch package manifests"

    validate_arch_packages "$SCRIPT_DIR/packages/common.txt"
    validate_arch_packages "$SCRIPT_DIR/packages/arch.txt"
    fi

    if [[ "$DISTRO_ID" == "arch" || "$DISTRO_LIKE" == *"arch"* ]]; then
    log "Checking installed packages"

    check_installed_arch_packages "$SCRIPT_DIR/packages/common.txt"
    check_installed_arch_packages "$SCRIPT_DIR/packages/arch.txt"
    show_package_summary
    fi

    log "Bootstrap foundation check complete"
}
main "$@"
