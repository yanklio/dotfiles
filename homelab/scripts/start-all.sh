#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HOMELAB_DIR="$(dirname "$SCRIPT_DIR")"
APPS_DIR="$HOMELAB_DIR/apps"
ENV_FILE="$HOMELAB_DIR/.env"

cd "$APPS_DIR"

[ -f "$ENV_FILE" ] && export $(grep -v '^#' "$ENV_FILE" | xargs)

bash "$SCRIPT_DIR/start-pihole-rootful.sh"

for container_dir in */; do
    if [ "$container_dir" = "pi-hole/" ]; then
        continue
    fi

    if [ -f "$container_dir/docker-compose.yml" ]; then
        echo "Starting $container_dir..."
        (cd "$container_dir" && podman compose --env-file "$ENV_FILE" up -d)
    fi
done

echo "All containers started."
