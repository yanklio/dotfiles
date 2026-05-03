pihole_dns_enabled() {
  truthy "${HOMELAB_ENABLE_PIHOLE_DNS:-false}"
}

should_start_pihole() {
  ! tailscale_only_mode || pihole_dns_enabled
}

start_optional_pihole() {
  if should_start_pihole; then
    start_pihole
  else
    echo "Skipping Pi-hole in tailscale-only mode."
  fi
}

pihole_dns_hosts_json() {
  local ip suffix names first=1 name

  if tailscale_only_mode; then
    ip="$(tailscale_ipv4)"
    suffix="${HOMELAB_TAILNET_DNS_SUFFIX:-$(hostname -s)}"
    names="${HOMELAB_TAILNET_DNS_NAMES:-${HOMELAB_APPS:-glance}}"
  else
    ip="${HOMELAB_IP:-}"
    suffix="${HOMELAB_DOMAIN:-${PIHOLE_DOMAIN:-home}}"
    names="${HOMELAB_DNS_NAMES:-pihole,glance}"
  fi

  [[ -n "$ip" ]] || die "No IP available for Pi-hole local DNS records"
  names="${names//,/ }"

  printf '['
  for name in $names; do
    name="$(trim_spaces "$name")"
    [[ -n "$name" ]] || continue

    [[ $first -eq 1 ]] || printf ','
    printf '"%s %s.%s"' "$ip" "$name" "$suffix"
    first=0
  done
  printf ']'
}

json_dns_hosts() {
  pihole_dns_hosts_json
}

start_pihole() {
  local pihole_dir="$apps_dir/pi-hole" env_args=(--env-file "$env_file")

  require_podman_compose
  have sudo || [[ $EUID -eq 0 ]] || die "sudo is required for rootful Pi-hole"
  load_homelab_env required
  validate_pihole_env
  [[ -f "$pihole_dir/docker-compose.yml" ]] || die "Missing $pihole_dir/docker-compose.yml"

  echo "Stopping rootless Pi-hole if it exists..."
  if dry_run; then
    run_cmd podman rm -f pihole
  else
    podman rm -f pihole >/dev/null 2>&1 || true
  fi

  if tailscale_only_mode; then
    echo "Starting Pi-hole rootful for tailnet DNS only..."
  else
    echo "Starting Pi-hole rootful for DNS/DHCP..."
  fi
  (cd "$pihole_dir" && as_root podman compose "${env_args[@]}" up -d)

  echo "Configuring Pi-hole local DNS records..."
  as_root_quiet podman exec pihole pihole-FTL --config dns.hosts "$(pihole_dns_hosts_json)"

  if tailscale_only_mode; then
    echo "Skipping Pi-hole DHCP configuration in tailscale-only mode."
  elif truthy "${DHCP_ACTIVE:-true}"; then
    echo "Configuring Pi-hole DHCP DNS option..."
    as_root_quiet podman exec pihole pihole-FTL --config misc.dnsmasq_lines "[\"dhcp-option=option:dns-server,$HOMELAB_IP\"]"
  fi

  if have systemctl && { have sudo || [[ $EUID -eq 0 ]]; }; then
    as_root_quiet systemctl enable --now podman-restart.service || true
  fi

  if pihole_dns_enabled && ! pihole_dns_listening; then
    die "Pi-hole DNS is enabled, but nothing is listening on UDP port 53."
  fi

  echo "Pi-hole rootful container started."
}

stop_pihole() {
  local pihole_dir="$apps_dir/pi-hole" env_args=()

  [[ -f "$pihole_dir/docker-compose.yml" ]] || return 0
  require_podman_compose
  [[ -f "$env_file" ]] && env_args=(--env-file "$env_file")

  if ! have sudo && [[ $EUID -ne 0 ]]; then
    warn "sudo is not available; skipping rootful Pi-hole stop"
    return 0
  fi

  echo "Stopping pi-hole..."
  (cd "$pihole_dir" && as_root podman compose "${env_args[@]}" down)
}

pihole_dns_listening() {
  local line

  have ss || return 0
  while IFS= read -r line; do
    [[ "$line" == *":53 "* ]] && return 0
  done < <(ss -lun 2>/dev/null)

  return 1
}
