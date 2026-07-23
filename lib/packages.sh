#!/usr/bin/env bash

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
    local package
    local packages=()

    mapfile -t packages < <(read_manifest "$manifest")

    log "$label packages: ${#packages[@]}"

    for package in "${packages[@]}"; do
        printf '  - %s\n' "$package"
    done
}

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
}

show_package_summary() {
    local package

    printf '\n'
    log "Package summary"
    printf '  Installed: %d\n' "${#INSTALLED_PACKAGES[@]}"
    printf '  Missing:   %d\n' "${#MISSING_PACKAGES[@]}"

    if ((${#MISSING_PACKAGES[@]} > 0)); then
        printf '\n'
        log "Packages requiring installation"

        for package in "${MISSING_PACKAGES[@]}"; do
            printf '  - %s\n' "$package"
        done
    fi
}

display_package_manifests() {
    show_packages "$SCRIPT_DIR/packages/common.txt" "Common"
    show_packages "$SCRIPT_DIR/packages/arch.txt" "Arch family"
}

validate_packages() {
    case "$DISTRO_LIKE" in
        arch)
            log "Validating Arch package manifests"
            validate_arch_packages "$SCRIPT_DIR/packages/common.txt"
            validate_arch_packages "$SCRIPT_DIR/packages/arch.txt"
            ;;
        *)
            error "Package validation is not implemented for: $DISTRO_LIKE"
            return 1
            ;;
    esac
}

check_packages() {
    INSTALLED_PACKAGES=()
    MISSING_PACKAGES=()

    case "$DISTRO_LIKE" in
        arch)
            log "Checking installed packages"
            check_installed_arch_packages "$SCRIPT_DIR/packages/common.txt"
            check_installed_arch_packages "$SCRIPT_DIR/packages/arch.txt"
            ;;
        *)
            error "Package checks are not implemented for: $DISTRO_LIKE"
            return 1
            ;;
    esac
}
