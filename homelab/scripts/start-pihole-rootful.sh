#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HOMELAB_DIR="$(dirname "$SCRIPT_DIR")"
PIHOLE_DIR="$HOMELAB_DIR/apps/pi-hole"
ENV_FILE="$HOMELAB_DIR/.env"

if [ ! -f "$ENV_FILE" ]; then
    echo "Missing $ENV_FILE. Copy homelab/.env.example to homelab/.env and set PIHOLE_PASSWORD." >&2
    exit 1
fi

set -a
# shellcheck disable=SC1090
source "$ENV_FILE"
set +a

if ! command -v sudo >/dev/null 2>&1; then
    echo "sudo is required to run Pi-hole rootful for DNS/DHCP." >&2
    exit 1
fi

echo "Stopping rootless Pi-hole if it exists..."
podman rm -f pihole >/dev/null 2>&1 || true

echo "Starting Pi-hole rootful for DNS/DHCP..."
(cd "$PIHOLE_DIR" && sudo podman compose --env-file "$ENV_FILE" up -d)

if [ -n "${HOMELAB_IP:-}" ]; then
    domain="${HOMELAB_DOMAIN:-${PIHOLE_DOMAIN:-home}}"
    names="${HOMELAB_DNS_NAMES:-pihole,glance}"
    dns_hosts="[]"

    IFS=',' read -ra name_list <<< "$names"
    for name in "${name_list[@]}"; do
        name="${name//[[:space:]]/}"
        [ -n "$name" ] || continue

        if [ "$dns_hosts" = "[]" ]; then
            dns_hosts="[\"$HOMELAB_IP $name.$domain\"]"
        else
            dns_hosts="${dns_hosts%]},\"$HOMELAB_IP $name.$domain\"]"
        fi
    done

    echo "Configuring Pi-hole local DNS records..."
    sudo podman exec pihole pihole-FTL --config dns.hosts "$dns_hosts" >/dev/null

    if [ "${DHCP_ACTIVE:-true}" = "true" ]; then
        echo "Configuring Pi-hole DHCP DNS option..."
        sudo podman exec pihole pihole-FTL --config misc.dnsmasq_lines "[\"dhcp-option=option:dns-server,$HOMELAB_IP\"]" >/dev/null
    fi
fi

if sudo systemctl list-unit-files podman-restart.service >/dev/null 2>&1; then
    sudo systemctl enable --now podman-restart.service >/dev/null 2>&1 || true
fi

echo "Pi-hole rootful container started."
