#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONTAINERS_DIR="$(dirname "$SCRIPT_DIR")"

cd "$CONTAINERS_DIR"

[ -f .env ] && export $(grep -v '^#' .env | xargs)

"$SCRIPT_DIR/start-pihole-rootful.sh"

for container_dir in */; do
    if [ "$container_dir" = "pi-hole/" ]; then
        continue
    fi

    if [ -f "$container_dir/docker-compose.yml" ]; then
        echo "Starting $container_dir..."
        (cd "$container_dir" && podman compose --env-file "$CONTAINERS_DIR/.env" up -d)
    fi
done

echo "All containers started."
