json_dns_hosts() {
  local domain names host first=1 name
  domain="${HOMELAB_DOMAIN:-${PIHOLE_DOMAIN:-home}}"
  names="${HOMELAB_DNS_NAMES:-pihole,glance}"
  names="${names//,/ }"

  printf '['
  for name in $names; do
    name="$(trim_spaces "$name")"
    [[ -n "$name" ]] || continue
    host="$HOMELAB_IP $name.$domain"
    [[ $first -eq 1 ]] || printf ','
    printf '"%s"' "$host"
    first=0
  done
  printf ']'
}

start_pihole() {
  local pihole_dir="$apps_dir/pi-hole" env_args=()
  require_podman_compose
  have sudo || [[ $EUID -eq 0 ]] || die "sudo is required for rootful Pi-hole"
  load_homelab_env required
  validate_pihole_env
  [[ -f "$pihole_dir/docker-compose.yml" ]] || die "Missing $pihole_dir/docker-compose.yml"
  env_args=(--env-file "$env_file")

  echo "Stopping rootless Pi-hole if it exists..."
  if dry_run; then
    run_cmd podman rm -f pihole
  else
    podman rm -f pihole >/dev/null 2>&1 || true
  fi

  echo "Starting Pi-hole rootful for DNS/DHCP..."
  (cd "$pihole_dir" && as_root podman compose "${env_args[@]}" up -d)

  if [[ -n "${HOMELAB_IP:-}" ]]; then
    echo "Configuring Pi-hole local DNS records..."
    if dry_run; then
      as_root podman exec pihole pihole-FTL --config dns.hosts "$(json_dns_hosts)"
    else
      as_root podman exec pihole pihole-FTL --config dns.hosts "$(json_dns_hosts)" >/dev/null
    fi

    if tailscale_only_mode; then
      echo "Skipping Pi-hole DHCP configuration in tailscale-only mode."
    elif truthy "${DHCP_ACTIVE:-true}"; then
      echo "Configuring Pi-hole DHCP DNS option..."
      if dry_run; then
        as_root podman exec pihole pihole-FTL --config misc.dnsmasq_lines "[\"dhcp-option=option:dns-server,$HOMELAB_IP\"]"
      else
        as_root podman exec pihole pihole-FTL --config misc.dnsmasq_lines "[\"dhcp-option=option:dns-server,$HOMELAB_IP\"]" >/dev/null
      fi
    fi
  fi

  if have systemctl && { have sudo || [[ $EUID -eq 0 ]]; }; then
    if dry_run; then
      as_root systemctl enable --now podman-restart.service || true
    else
      as_root systemctl enable --now podman-restart.service >/dev/null 2>&1 || true
    fi
  fi

  echo "Pi-hole rootful container started."
}

stop_pihole() {
  local pihole_dir="$apps_dir/pi-hole" env_args=()
  [[ -f "$pihole_dir/docker-compose.yml" ]] || return 0
  require_podman_compose

  [[ -f "$env_file" ]] && env_args=(--env-file "$env_file")

  if have sudo || [[ $EUID -eq 0 ]]; then
    echo "Stopping pi-hole..."
    (cd "$pihole_dir" && as_root podman compose "${env_args[@]}" down)
  else
    warn "sudo is not available; skipping rootful Pi-hole stop"
  fi
}

configure_homelab_nginx() {
  local bootstrap="$dotfiles_dir/chezmoi/scripts/bootstrap.sh"
  [[ -x "$bootstrap" ]] || die "Missing executable bootstrap script: $bootstrap"

  if dry_run; then
    DOTFILES_DRY_RUN=1 run_cmd "$bootstrap" nginx
  else
    "$bootstrap" nginx
  fi
}
