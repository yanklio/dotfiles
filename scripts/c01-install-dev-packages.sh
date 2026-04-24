#!/bin/bash
set -euo pipefail

if ! command -v go >/dev/null 2>&1; then
    echo "Go not found. Skipping dev packages."
    exit 0
fi

echo "Installing lazygit..."
go install github.com/jesseduffield/lazygit@latest

GOPATH="${GOPATH:-$HOME/go}"
export PATH="$GOPATH/bin:$PATH"

if command -v lazygit >/dev/null 2>&1; then
    echo "lazygit installed."
fi
