homelab_apps() {
  local apps="${HOMELAB_APPS:-glance}" app
  apps="${apps//,/ }"

  for app in $apps; do
    app="$(trim_spaces "$app")"
    [[ -n "$app" && "$app" != "pi-hole" ]] || continue
    printf '%s\n' "$app"
  done
}

compose_in_app() {
  local app="$1" app_dir="$apps_dir/$app"
  shift

  [[ -f "$app_dir/docker-compose.yml" ]] || die "Missing compose file for $app: $app_dir/docker-compose.yml"

  local env_args=()
  [[ -f "$env_file" ]] && env_args=(--env-file "$env_file")
  if tailscale_only_mode; then
    (cd "$app_dir" && HOMELAB_APP_BIND=127.0.0.1 run_cmd podman compose "${env_args[@]}" "$@")
  else
    (cd "$app_dir" && run_cmd podman compose "${env_args[@]}" "$@")
  fi
}

start_rootless_apps() {
  local app
  require_podman_compose

  while IFS= read -r app; do
    echo "Starting $app..."
    compose_in_app "$app" up -d
  done < <(homelab_apps)
}

stop_rootless_apps() {
  local app
  require_podman_compose

  while IFS= read -r app; do
    echo "Stopping $app..."
    compose_in_app "$app" down
  done < <(homelab_apps)
}

show_homelab_status() {
  load_homelab_env optional

  echo "Rootless containers:"
  if have podman; then
    run_cmd podman ps --format 'table {{.Names}}\t{{.Status}}\t{{.Ports}}'
  else
    echo "podman is not installed"
  fi

  echo
  echo "Rootful containers:"
  if have podman && { have sudo || [[ $EUID -eq 0 ]]; }; then
    as_root podman ps --format 'table {{.Names}}\t{{.Status}}\t{{.Ports}}'
  else
    echo "sudo or podman is not installed"
  fi

  echo
  show_tailscale_access_urls
}

check_unsafe_app_ports() {
  local failed=0 name ports

  have podman || return 0
  while IFS=$'\t' read -r name ports; do
    [[ -n "$name" ]] || continue
    case "$ports" in
      *0.0.0.0* | *:::* | *'[::]'*)
        warn "$name exposes ports on all interfaces: $ports"
        failed=1
        ;;
    esac
  done < <(podman ps --format '{{.Names}}\t{{.Ports}}')

  return "$failed"
}

doctor() {
  local failed=0 app

  [[ -f "$env_file" ]] && load_homelab_env optional

  echo "Checking homelab prerequisites..."
  have podman || { warn "podman is not installed"; failed=1; }
  if have podman; then
    podman compose version >/dev/null 2>&1 || { warn "podman compose is not available"; failed=1; }
  fi
  tailscale_only_mode || have sudo || [[ $EUID -eq 0 ]] || { warn "sudo is required for rootful Pi-hole"; failed=1; }

  if [[ -f "$env_file" ]]; then
    load_homelab_env optional
    validate_homelab_env || failed=1
    echo "Access mode: $(homelab_access_mode)"
    if tailscale_only_mode; then
      echo "Tailscale IPv4: $(tailscale_ipv4)"
    elif [[ -z "${PIHOLE_PASSWORD:-}" ]]; then
      warn "PIHOLE_PASSWORD is not set"
      failed=1
    fi
  else
    warn "$env_file is missing"
    failed=1
  fi

  while IFS= read -r app; do
    [[ -f "$apps_dir/$app/docker-compose.yml" ]] || { warn "Missing compose file for $app"; failed=1; }
  done < <(homelab_apps)

  if tailscale_only_mode; then
    check_unsafe_app_ports || failed=1
    show_tailscale_access_urls
  fi

  if [[ $failed -eq 0 ]]; then
    echo "Homelab doctor passed."
  else
    echo "Homelab doctor found issues." >&2
  fi

  return "$failed"
}
