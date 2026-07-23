#!/usr/bin/env bash

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

install_packages() {
    case "$DISTRO_LIKE" in
        arch)
            install_missing_arch_packages
            ;;
        *)
            error "Package installation is not implemented for: $DISTRO_LIKE"
            return 1
            ;;
    esac
}
