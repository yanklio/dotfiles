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

if ! command -v sudo >/dev/null 2>&1; then
    echo "sudo is required to run Pi-hole rootful for DNS/DHCP." >&2
    exit 1
fi

echo "Stopping rootless Pi-hole if it exists..."
podman rm -f pihole >/dev/null 2>&1 || true

echo "Starting Pi-hole rootful for DNS/DHCP..."
(cd "$PIHOLE_DIR" && sudo podman compose --env-file "$ENV_FILE" up -d)

if sudo systemctl list-unit-files podman-restart.service >/dev/null 2>&1; then
    sudo systemctl enable --now podman-restart.service >/dev/null 2>&1 || true
fi

echo "Pi-hole rootful container started."
