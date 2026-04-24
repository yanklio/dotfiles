#!/bin/bash
set -euo pipefail

if ! command -v systemctl >/dev/null 2>&1; then
    echo "systemd not found."
    exit 0
fi

if command -v ollama >/dev/null 2>&1; then
    systemctl --user enable --now ollama 2>/dev/null || sudo systemctl enable --now ollama 2>/dev/null || true
fi

if command -v podman >/dev/null 2>&1; then
    mkdir -p "$HOME/.config/systemd/user"
    cat > "$HOME/.config/systemd/user/podman-auto-update.service" << 'EOF'
[Unit]
Description=Podman auto-update

[Service]
Type=oneshot
ExecStart=/usr/bin/podman system df
EOF
    systemctl --user daemon-reload
    systemctl --user enable podman-auto-update.service 2>/dev/null || true
fi
