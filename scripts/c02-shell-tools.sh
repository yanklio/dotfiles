#!/bin/bash
set -euo pipefail

if [[ -d "$HOME/.oh-my-zsh" ]]; then
    echo "oh-my-zsh already installed."
else
    echo "Installing oh-my-zsh..."
    RUNZSH=no CHSH=no KEEP_ZSHRC=yes sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
fi
