doctor() {
  local failed=0 app name ports

  [[ -f "$env_file" ]] && load_homelab_env optional

  echo "Checking homelab prerequisites..."

  if ! have podman; then
    warn "podman is not installed"
    failed=1
  elif ! podman compose version >/dev/null 2>&1; then
    warn "podman compose is not available"
    failed=1
  fi

  if should_start_pihole && ! have sudo && [[ $EUID -ne 0 ]]; then
    warn "sudo is required for rootful Pi-hole"
    failed=1
  fi

  if [[ -f "$env_file" ]]; then
    validate_homelab_env || failed=1
    echo "Access mode: $(homelab_access_mode)"
  else
    warn "$env_file is missing"
    failed=1
  fi

  if tailscale_only_mode; then
    echo "Tailscale IPv4: $(tailscale_ipv4)"

    if pihole_dns_enabled; then
      echo "Tailnet DNS: Pi-hole enabled for $(pihole_dns_hosts_json)"
      [[ -n "${PIHOLE_PASSWORD:-}" ]] || { warn "PIHOLE_PASSWORD is required when HOMELAB_ENABLE_PIHOLE_DNS=true"; failed=1; }
      pihole_dns_listening || { warn "Pi-hole DNS is enabled, but UDP port 53 is not listening"; failed=1; }
    fi
  elif [[ -z "${PIHOLE_PASSWORD:-}" ]]; then
    warn "PIHOLE_PASSWORD is not set"
    failed=1
  fi

  while IFS= read -r app; do
    [[ -f "$apps_dir/$app/docker-compose.yml" ]] || { warn "Missing compose file for $app"; failed=1; }
  done < <(homelab_apps)

  if tailscale_only_mode && have podman; then
    while IFS=$'\t' read -r name ports; do
      [[ -n "$name" ]] || continue
      case "$ports" in
        *0.0.0.0* | *:::* | *'[::]'*) warn "$name exposes ports on all interfaces: $ports"; failed=1 ;;
      esac
    done < <(podman ps --format '{{.Names}}\t{{.Ports}}')

    show_tailscale_access_urls
  fi

  if [[ $failed -eq 0 ]]; then
    echo "Homelab doctor passed."
  else
    echo "Homelab doctor found issues." >&2
  fi

  return "$failed"
}
