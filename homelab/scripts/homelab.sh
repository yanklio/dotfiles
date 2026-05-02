#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
homelab_dir="$(dirname "$script_dir")"
dotfiles_dir="$(dirname "$homelab_dir")"
apps_dir="$homelab_dir/apps"
env_file="$homelab_dir/.env"

source "$script_dir/lib/common.sh"
source "$script_dir/lib/env.sh"
source "$script_dir/lib/apps.sh"
source "$script_dir/lib/pihole.sh"

usage() {
  cat <<EOF
Usage: $0 [command]

Environment:
  HOMELAB_DRY_RUN=1  Print actions without running them
  DOTFILES_DRY_RUN=1 Alias for HOMELAB_DRY_RUN compatibility

Commands:
  start     Start Pi-hole rootful and rootless apps (default)
  stop      Stop rootless apps and Pi-hole
  restart   Stop, then start the homelab stack
  status    Show rootless and rootful container status
  doctor    Validate tools, env, and app inventory
  pihole    Start/configure only rootful Pi-hole
  nginx     Apply homelab nginx reverse-proxy config
  help      Show this help
EOF
}

homelab_start() {
  load_homelab_env required
  validate_homelab_env
  start_pihole
  start_rootless_apps
  echo "All homelab containers started."
}

homelab_stop() {
  load_homelab_env optional
  validate_homelab_apps
  stop_rootless_apps
  stop_pihole
  echo "All homelab containers stopped."
}

run_command() {
  case "$1" in
    start) homelab_start ;;
    stop) homelab_stop ;;
    restart) homelab_stop; homelab_start ;;
    status) show_homelab_status ;;
    doctor) doctor ;;
    pihole) start_pihole ;;
    nginx) configure_homelab_nginx ;;
    help | -h | --help) usage ;;
    *)
      printf 'Unknown homelab command: %s\n\n' "$1" >&2
      usage >&2
      exit 2
      ;;
  esac
}

main() {
  local command="${1:-start}"

  if [[ "$command" == "help" || "$command" == "-h" || "$command" == "--help" ]]; then
    usage
    return 0
  fi

  dry_run && echo "Running homelab command in dry-run mode..."
  run_command "$command"
}

main "$@"
