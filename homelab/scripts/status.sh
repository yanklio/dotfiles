#!/usr/bin/env bash
set -euo pipefail

echo "Rootless containers:"
if command -v podman >/dev/null 2>&1; then
  podman ps --format 'table {{.Names}}\t{{.Status}}\t{{.Ports}}'
else
  echo "podman is not installed"
fi

echo
echo "Rootful containers:"
if command -v sudo >/dev/null 2>&1 && command -v podman >/dev/null 2>&1; then
  sudo podman ps --format 'table {{.Names}}\t{{.Status}}\t{{.Ports}}'
else
  echo "sudo or podman is not installed"
fi
