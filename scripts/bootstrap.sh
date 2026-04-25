#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "Running bootstrap..."

bash "$SCRIPT_DIR/c00-install-base-packages.sh"
bash "$SCRIPT_DIR/c01-install-dev-packages.sh"
bash "$SCRIPT_DIR/c02-shell-tools.sh"
bash "$SCRIPT_DIR/c03-install-node-npm-globals.sh"
bash "$SCRIPT_DIR/c04-install-cli-tools.sh"
bash "$SCRIPT_DIR/c04-install-flatpaks.sh"
bash "$SCRIPT_DIR/c05-setup-systemd-services.sh"
bash "$SCRIPT_DIR/e01-setup-gnome.sh"

echo "Bootstrap complete."
