#!/bin/bash
set -euo pipefail

PACKAGES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/packages"
DISTRO_PACKAGES_FILE="$PACKAGES_DIR/${PKG:-dnf}.txt"

if [[ "${IS_FEDORA:-true}" != "true" ]]; then
    echo "Skipping dnf packages for non-Fedora profile."
    exit 0
fi

read_packages() {
    grep -v -E '^\s*#' "$1" | grep -v -E '^\s*$' || true
}

join_packages() {
    local files=("$@")
    local all_packages=()
    for file in "${files[@]}"; do
        while IFS= read -r pkg; do
            [[ -n "$pkg" ]] && all_packages+=("$pkg")
        done < <(read_packages "$file")
    done
    printf '%s\n' "${all_packages[@]}" | sort -u
}

if ! command -v dnf >/dev/null 2>&1; then
    echo "dnf is required for Fedora package installation."
    exit 1
fi

packages=()
while IFS= read -r pkg; do
    [[ -n "$pkg" ]] && packages+=("$pkg")
done < <(join_packages "$PACKAGES_DIR/common.txt" "$DISTRO_PACKAGES_FILE")

if [[ ${#packages[@]} -eq 0 ]]; then
    echo "No packages to install."
    exit 0
fi

installable_packages=()
skipped_packages=()

for pkg in "${packages[@]}"; do
    if rpm -q "$pkg" >/dev/null 2>&1 || dnf -q list --available "$pkg" >/dev/null 2>&1; then
        installable_packages+=("$pkg")
    else
        skipped_packages+=("$pkg")
    fi
done

if [[ ${#skipped_packages[@]} -gt 0 ]]; then
    echo "Skipping unavailable packages: ${skipped_packages[*]}"
fi

if [[ ${#installable_packages[@]} -eq 0 ]]; then
    echo "No installable dnf packages found."
    exit 0
fi

echo "Installing packages: ${installable_packages[*]}"

if [[ $EUID -eq 0 ]]; then
    dnf install -y "${installable_packages[@]}"
else
    if [[ ! -t 0 ]]; then
        echo "No TTY available for sudo."
        exit 0
    fi
    sudo dnf install -y "${installable_packages[@]}"
fi
