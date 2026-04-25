#!/bin/bash
set -euo pipefail

if command -v zed >/dev/null 2>&1; then
    echo "Zed already installed."
else
    echo "Installing Zed..."
    curl -f https://zed.dev/install.sh | sh
fi

if command -v ollama >/dev/null 2>&1; then
    echo "Ollama already installed."
else
    echo "Installing Ollama..."
    curl -fsSL https://ollama.com/install.sh | sh
fi
