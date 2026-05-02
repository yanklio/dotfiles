#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
homelab_dir="$(dirname "$script_dir")"
pihole_dir="$homelab_dir/apps/pi-hole"
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

require_env() {
  local name="$1"
  [[ -n "${!name:-}" ]] || {
    echo "$name must be set in $env_file" >&2
    exit 1
  }
}

json_dns_hosts() {
  local domain names host entries=()
  domain="${HOMELAB_DOMAIN:-${PIHOLE_DOMAIN:-home}}"
  names="${HOMELAB_DNS_NAMES:-pihole,glance}"

  IFS=',' read -ra entries <<< "$names"
  printf '['
  local first=1 name
  for name in "${entries[@]}"; do
    name="${name//[[:space:]]/}"
    [[ -n "$name" ]] || continue
    host="$HOMELAB_IP $name.$domain"
    [[ $first -eq 1 ]] || printf ','
    printf '"%s"' "$host"
    first=0
  done
  printf ']'
}

main() {
  require podman
  require sudo
  podman compose version >/dev/null 2>&1 || {
    echo "podman compose is required" >&2
    exit 1
  }

  load_env
  require_env PIHOLE_PASSWORD

  echo "Stopping rootless Pi-hole if it exists..."
  podman rm -f pihole >/dev/null 2>&1 || true

  echo "Starting Pi-hole rootful for DNS/DHCP..."
  (cd "$pihole_dir" && sudo podman compose --env-file "$env_file" up -d)

  if [[ -n "${HOMELAB_IP:-}" ]]; then
    echo "Configuring Pi-hole local DNS records..."
    sudo podman exec pihole pihole-FTL --config dns.hosts "$(json_dns_hosts)" >/dev/null

    if [[ "${DHCP_ACTIVE:-true}" == "true" ]]; then
      echo "Configuring Pi-hole DHCP DNS option..."
      sudo podman exec pihole pihole-FTL --config misc.dnsmasq_lines "[\"dhcp-option=option:dns-server,$HOMELAB_IP\"]" >/dev/null
    fi
  fi

  if sudo systemctl list-unit-files podman-restart.service >/dev/null 2>&1; then
    sudo systemctl enable --now podman-restart.service >/dev/null 2>&1 || true
  fi

  echo "Pi-hole rootful container started."
}

main "$@"
