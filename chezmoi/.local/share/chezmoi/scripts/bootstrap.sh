#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
packages_dir="$script_dir/packages"

read_packages() {
    grep -v -E '^\s*(#|$)' "$1" || true
}

install_fedora_packages() {
    [[ "${IS_FEDORA:-true}" == "true" ]] || return 0
    command -v dnf >/dev/null 2>&1 || return 0

    mapfile -t packages < <(read_packages "$packages_dir/common.txt"; read_packages "$packages_dir/dnf.txt")
    [[ ${#packages[@]} -gt 0 ]] || return 0

    echo "Installing Fedora packages..."
    if [[ $EUID -eq 0 ]]; then
        dnf install -y "${packages[@]}"
    elif [[ -t 0 ]]; then
        sudo dnf install -y "${packages[@]}"
    else
        echo "No TTY available for sudo; skipping Fedora packages."
    fi
}

install_go_tools() {
    command -v go >/dev/null 2>&1 || return 0

    echo "Installing Go tools..."
    go install github.com/jesseduffield/lazygit@latest
}

install_oh_my_zsh() {
    [[ ! -d "$HOME/.oh-my-zsh" ]] || return 0

    echo "Installing oh-my-zsh..."
    RUNZSH=no CHSH=no KEEP_ZSHRC=yes sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
}

install_npm_packages() {
    command -v npm >/dev/null 2>&1 || return 0

    mapfile -t packages < <(read_packages "$packages_dir/npm.txt")
    [[ ${#packages[@]} -gt 0 ]] || return 0

    echo "Installing npm packages..."
    npm install --global --prefix "$HOME/.local" "${packages[@]}"
}

install_extra_cli_tools() {
    if ! command -v zed >/dev/null 2>&1; then
        echo "Installing Zed..."
        curl -f https://zed.dev/install.sh | sh
    fi

    if ! command -v ollama >/dev/null 2>&1; then
        echo "Installing Ollama..."
        curl -fsSL https://ollama.com/install.sh | sh
    fi
}

install_flatpaks() {
    command -v flatpak >/dev/null 2>&1 || return 0

    for app in com.discord.Discord com.slack.Slack com.google.Chrome app.zen_browser.zen; do
        flatpak info --system "$app" >/dev/null 2>&1 && continue
        flatpak install -y flathub "$app" 2>/dev/null || echo "Skipping $app; install manually if needed."
    done
}

enable_services() {
    command -v systemctl >/dev/null 2>&1 || return 0

    if command -v ollama >/dev/null 2>&1; then
        systemctl --user enable --now ollama 2>/dev/null || sudo systemctl enable --now ollama 2>/dev/null || true
    fi
}

apply_gnome_settings() {
    [[ "${IS_GNOME:-true}" == "true" ]] || return 0
    command -v gsettings >/dev/null 2>&1 || return 0

    echo "Applying GNOME settings..."
    gsettings set org.gnome.desktop.wm.keybindings close "['<Super>w']"
    gsettings set org.gnome.desktop.wm.keybindings maximize "['<Super>Up']"
    gsettings set org.gnome.desktop.wm.keybindings begin-resize "['<Super>BackSpace']"
    gsettings set org.gnome.desktop.wm.keybindings toggle-fullscreen "['<Shift>F11']"
    gsettings set org.gnome.mutter dynamic-workspaces false
    gsettings set org.gnome.desktop.wm.preferences num-workspaces 6

    for i in 1 2 3 4 5 6 7 8 9; do
        gsettings set org.gnome.shell.keybindings "switch-to-application-$i" "['<Alt>$i']"
    done

    for i in 1 2 3 4 5 6; do
        gsettings set org.gnome.desktop.wm.keybindings "switch-to-workspace-$i" "['<Super>$i']"
    done
}

echo "Running bootstrap..."
install_fedora_packages
install_go_tools
install_oh_my_zsh
install_npm_packages
install_extra_cli_tools
install_flatpaks
enable_services
apply_gnome_settings
echo "Bootstrap complete."
