#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
packages_dir="$script_dir/packages"
post_setup_notes=()

source "$script_dir/lib/common.sh"
source "$script_dir/lib/packages.sh"
source "$script_dir/lib/tools.sh"
source "$script_dir/lib/services.sh"
source "$script_dir/lib/desktop.sh"

run_all() {
  install_system_packages
  install_go_tools
  install_oh_my_zsh
  install_npm_packages
  install_extra_cli_tools
  install_flatpaks
  enable_services
  is_homelab_server && configure_nginx_proxy
  apply_gnome_settings
}

usage() {
  cat <<EOF
Usage: $0 [section ...]

Environment:
  DOTFILES_DRY_RUN=1  Print actions without running them

Sections:
  all       Run every bootstrap section (default)
  packages  Install role-based system packages with dnf/apt
  go        Install Go tools
  shell     Install oh-my-zsh
  npm       Install npm global packages
  upstream  Install upstream CLI tools
  flatpak   Install Flatpak apps
  services  Enable user/system services
  nginx     Configure host nginx reverse proxy
  gnome     Apply GNOME settings when enabled/detected
EOF
}

run_section() {
  case "$1" in
    all) run_all ;;
    packages) install_system_packages ;;
    go) install_go_tools ;;
    shell) install_oh_my_zsh ;;
    npm) install_npm_packages ;;
    upstream) install_extra_cli_tools ;;
    flatpak | flatpaks) install_flatpaks ;;
    services) enable_services ;;
    nginx) configure_nginx_proxy ;;
    gnome) apply_gnome_settings ;;
    help | -h | --help) usage ;;
    *)
      printf 'Unknown bootstrap section: %s\n\n' "$1" >&2
      usage >&2
      exit 2
      ;;
  esac
}

main() {
  if [[ "${1:-}" == "help" || "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
    usage
    return 0
  fi

  dry_run && echo "Running bootstrap in dry-run mode..." || echo "Running bootstrap..."

  if [[ $# -eq 0 ]]; then
    run_all
  else
    for section in "$@"; do
      run_section "$section"
    done
  fi

  print_post_setup_notes
  echo "Bootstrap complete."
}

main "$@"
