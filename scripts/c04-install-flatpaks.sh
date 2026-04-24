#!/bin/bash
set -euo pipefail

if ! command -v flatpak >/dev/null 2>&1; then
    echo "Flatpak not found."
    exit 0
fi

for app in com.discord.Discord com.slack.Slack com.google.Chrome app.zen_browser.zen; do
    if flatpak info --system "$app" >/dev/null 2>&1; then
        echo "$app already installed."
        continue
    fi

    echo "Installing $app (may prompt for selection)..."
    if ! flatpak install -y flathub "$app" 2>/dev/null; then
        echo "Skipping $app (install manually if needed)."
    fi
done
