source "$SCRIPT_DIR/lib/context.sh"
source "$SCRIPT_DIR/lib/logging.sh"
source "$SCRIPT_DIR/lib/args.sh"

#!/usr/bin/env bash

usage() {
    cat <<'EOF'
Usage: bootstrap.sh [OPTIONS]

Options:
  --dry-run   Show what JonOS would do without making changes
  --install   Install missing packages
  -h, --help  Show this help message
EOF
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
