#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
homelab_dir="$(dirname "$script_dir")"
apps_dir="$homelab_dir/apps"
env_file="$homelab_dir/.env"

have() {
  command -v "$1" >/dev/null 2>&1
}

require() {
  have "$1" || {
    echo "$1 is required" >&2
    exit 1
  }
}

load_env() {
  [[ -f "$env_file" ]] || {
    echo "Missing $env_file. Copy homelab/.env.example to homelab/.env and set PIHOLE_PASSWORD." >&2
    exit 1
  }

  set -a
  # shellcheck disable=SC1090
  source "$env_file"
  set +a
}

start_app() {
  local app="$1" app_dir="$apps_dir/$app"
  [[ -f "$app_dir/docker-compose.yml" ]] || {
    echo "Skipping $app; missing docker-compose.yml" >&2
    return 0
  }

  echo "Starting $app..."
  (cd "$app_dir" && podman compose --env-file "$env_file" up -d)
}

main() {
  require podman
  podman compose version >/dev/null 2>&1 || {
    echo "podman compose is required" >&2
    exit 1
  }

  load_env
  bash "$script_dir/start-pihole-rootful.sh"

  local app apps
  apps="${HOMELAB_APPS:-glance}"
  for app in $apps; do
    [[ "$app" != "pi-hole" ]] || continue
    start_app "$app"
  done

  echo "All homelab containers started."
}

main "$@"
