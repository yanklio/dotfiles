#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PACKAGES_FILE="$SCRIPT_DIR/packages/npm.txt"

read_packages() {
    grep -v -E '^\s*#' "$1" | grep -v -E '^\s*$' || true
}

if ! command -v npm >/dev/null 2>&1; then
    echo "npm not found."
    exit 1
fi

packages=()
while IFS= read -r pkg; do
    [[ -n "$pkg" ]] && packages+=("$pkg")
done < <(read_packages "$PACKAGES_FILE")

if [[ ${#packages[@]} -eq 0 ]]; then
    echo "No npm packages to install."
    exit 0
fi

export PATH="$HOME/.local/bin:$PATH"
npm install --global --prefix "$HOME/.local" "${packages[@]}"
