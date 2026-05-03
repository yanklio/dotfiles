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
