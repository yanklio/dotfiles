#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
homelab_dir="$(dirname "$script_dir")"
apps_dir="$homelab_dir/apps"
env_file="$homelab_dir/.env"

have() {
  command -v "$1" >/dev/null 2>&1
}

stop_app() {
  local app="$1" app_dir="$apps_dir/$app"
  [[ -f "$app_dir/docker-compose.yml" ]] || return 0

  echo "Stopping $app..."
  (cd "$app_dir" && podman compose --env-file "$env_file" down)
}

main() {
  have podman || {
    echo "podman is required" >&2
    exit 1
  }

  local app apps
  apps="${HOMELAB_APPS:-glance}"
  for app in $apps; do
    [[ "$app" != "pi-hole" ]] || continue
    stop_app "$app"
  done

  if have sudo && [[ -f "$apps_dir/pi-hole/docker-compose.yml" ]]; then
    echo "Stopping pi-hole..."
    (cd "$apps_dir/pi-hole" && sudo podman compose --env-file "$env_file" down)
  fi

  echo "All homelab containers stopped."
}

main "$@"
