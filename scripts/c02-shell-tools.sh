#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [[ -d "$HOME/.oh-my-zsh" ]]; then
    echo "oh-my-zsh already installed."
else
    echo "Installing oh-my-zsh..."
    RUNZSH=no CHSH=no KEEP_ZSHRC=yes sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
fi

if command -v zed >/dev/null 2>&1; then
    echo "Zed already installed."
else
    echo "Installing Zed..."
    curl -f https://zed.dev/install.sh | sh
fi
