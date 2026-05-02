#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
packages_dir="$script_dir/packages"
post_setup_notes=()

have() {
  command -v "$1" >/dev/null 2>&1
}

add_post_setup_note() {
  local note="$1"
  [[ -n "$note" ]] || return 0
  post_setup_notes+=("$note")
}

dotfiles_root() {
  local root

  root="$(cd "$script_dir/../../../../.." && pwd)"
  [[ -d "$root/containers" ]] || return 1
  printf '%s\n' "$root"
}

nginx_bin() {
  if command -v nginx >/dev/null 2>&1; then
    command -v nginx
  elif [[ -x /usr/sbin/nginx ]]; then
    printf '%s\n' /usr/sbin/nginx
  elif [[ -x /usr/bin/nginx ]]; then
    printf '%s\n' /usr/bin/nginx
  else
    return 1
  fi
}

read_list() {
  local file="$1"
  local line

  [[ -r "$file" ]] || return 0

  while IFS= read -r line || [[ -n "$line" ]]; do
    [[ "$line" =~ ^[[:space:]]*(#|$) ]] && continue
    printf '%s\n' "$line"
  done < "$file"
}

install_fedora_packages() {
  have dnf || return 0

  mapfile -t packages < <(read_list "$packages_dir/common.txt"; read_list "$packages_dir/dnf.txt")
  [[ ${#packages[@]} -gt 0 ]] || return 0

  echo "Installing Fedora packages..."
  if [[ $EUID -eq 0 ]]; then
    dnf install -y "${packages[@]}"
  elif [[ -t 0 ]] && have sudo; then
    sudo dnf install -y "${packages[@]}"
  else
    echo "No TTY available for sudo; skipping Fedora packages."
  fi
}

install_apt_packages() {
  have apt-get || return 0

  mapfile -t packages < <(read_list "$packages_dir/common.txt"; read_list "$packages_dir/apt.txt")
  [[ ${#packages[@]} -gt 0 ]] || return 0

  echo "Installing Debian/Ubuntu packages..."
  if [[ $EUID -eq 0 ]]; then
    apt-get install -y "${packages[@]}"
  elif [[ -t 0 ]] && have sudo; then
    sudo apt-get install -y "${packages[@]}"
  else
    echo "No TTY available for sudo; skipping apt packages."
  fi
}

install_go_tools() {
  have go || return 0

  mapfile -t tools < <(read_list "$packages_dir/go.txt")
  [[ ${#tools[@]} -gt 0 ]] || return 0

  echo "Installing Go tools..."
  for tool in "${tools[@]}"; do
    go install "$tool"
  done
}

install_oh_my_zsh() {
  have curl || return 0
  [[ ! -d "$HOME/.oh-my-zsh" ]] || return 0

  echo "Installing oh-my-zsh..."
  RUNZSH=no CHSH=no KEEP_ZSHRC=yes sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
}

install_npm_packages() {
  have npm || return 0

  mapfile -t packages < <(read_list "$packages_dir/npm.txt")
  [[ ${#packages[@]} -gt 0 ]] || return 0

  echo "Installing npm packages..."
  npm install --global --prefix "$HOME/.local" "${packages[@]}"
}

install_extra_cli_tools() {
  have curl || return 0

  local command_name display_name install_url

  while IFS='|' read -r command_name display_name install_url; do
    [[ -n "$command_name" && -n "$display_name" && -n "$install_url" ]] || continue
    have "$command_name" && continue

    echo "Installing $display_name..."
    curl -fsSL "$install_url" | sh

    case "$command_name" in
      tailscale)
        add_post_setup_note "Tailscale: run 'sudo tailscale up' to complete setup."
        ;;
    esac
  done < <(read_list "$packages_dir/upstream.txt")
}

print_post_setup_notes() {
  [[ ${#post_setup_notes[@]} -gt 0 ]] || return 0

  echo
  echo "Post-setup notes:"
  for note in "${post_setup_notes[@]}"; do
    echo "- $note"
  done
}

install_flatpaks() {
  have flatpak || return 0

  mapfile -t apps < <(read_list "$packages_dir/flatpak.txt")
  [[ ${#apps[@]} -gt 0 ]] || return 0

  echo "Installing Flatpaks..."
  for app in "${apps[@]}"; do
    flatpak info "$app" >/dev/null 2>&1 && continue
    flatpak install --noninteractive --user -y flathub "$app" 2>/dev/null \
      || flatpak install --noninteractive --system -y flathub "$app" 2>/dev/null \
      || echo "Skipping $app; install manually if needed."
  done
}

enable_services() {
  have systemctl || return 0

  if have ollama; then
    echo "Enabling ollama service..."
    systemctl --user enable --now ollama 2>/dev/null \
      || { have sudo && sudo systemctl enable --now ollama; } \
      || echo "Warning: could not enable ollama service"
  fi

  if have podman; then
    echo "Enabling podman.socket..."
    systemctl --user enable --now podman.socket 2>/dev/null \
      || { have sudo && sudo systemctl enable --now podman.socket; } \
      || echo "Warning: could not enable podman.socket"
  fi
}

configure_nginx_proxy() {
  local root conf dest nginx
  nginx="$(nginx_bin)" || return 0
  root="$(dotfiles_root)" || return 0
  conf="$root/services/nginx/conf.d/home-lab.conf"
  dest="/etc/nginx/conf.d/home-lab.conf"

  [[ -r "$conf" ]] || return 0

  echo "Configuring nginx reverse proxy..."
  if [[ $EUID -eq 0 ]]; then
    mkdir -p /etc/nginx/conf.d
    disable_default_nginx_sites
    ln -sf "$conf" "$dest"
    "$nginx" -t
    systemctl enable --now nginx
    systemctl reload nginx
  elif [[ -t 0 ]] && have sudo; then
    sudo mkdir -p /etc/nginx/conf.d
    sudo bash -c 'if [[ -L /etc/nginx/sites-enabled/default ]]; then rm /etc/nginx/sites-enabled/default; elif [[ -e /etc/nginx/sites-enabled/default ]]; then mv -n /etc/nginx/sites-enabled/default /etc/nginx/sites-available/default.disabled; fi; for site in /etc/nginx/conf.d/default.conf /etc/nginx/conf.d/welcome.conf; do [[ -e "$site" ]] || continue; mv -n "$site" "$site.disabled"; done'
    sudo ln -sf "$conf" "$dest"
    sudo "$nginx" -t
    sudo systemctl enable --now nginx
    sudo systemctl reload nginx
  else
    echo "No TTY available for sudo; skipping nginx reverse proxy setup."
    add_post_setup_note "Nginx: run 'bash ~/Dotfiles/chezmoi/.local/share/chezmoi/scripts/bootstrap.sh nginx' from an interactive shell."
  fi
}

disable_default_nginx_sites() {
  local site

  if [[ -L /etc/nginx/sites-enabled/default ]]; then
    rm /etc/nginx/sites-enabled/default
  elif [[ -e /etc/nginx/sites-enabled/default ]]; then
    mv -n /etc/nginx/sites-enabled/default /etc/nginx/sites-available/default.disabled
  fi

  for site in /etc/nginx/conf.d/default.conf /etc/nginx/conf.d/welcome.conf; do
    [[ -e "$site" ]] || continue
    mv -n "$site" "$site.disabled"
  done
}

is_gnome() {
  local desktop="${XDG_CURRENT_DESKTOP:-}:${XDG_SESSION_DESKTOP:-}:${DESKTOP_SESSION:-}"
  [[ "${desktop,,}" == *gnome* ]]
}

apply_gnome_settings() {
  have gsettings || return 0
  is_gnome || return 0

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

run_all() {
  install_fedora_packages
  install_apt_packages
  install_go_tools
  install_oh_my_zsh
  install_npm_packages
  install_extra_cli_tools
  install_flatpaks
  enable_services
  configure_nginx_proxy
  apply_gnome_settings
}

usage() {
  cat <<EOF
Usage: $0 [section ...]

Sections:
  all       Run every bootstrap section (default)
  packages  Install system packages with dnf/apt when available
  go        Install Go tools
  shell     Install oh-my-zsh
  npm       Install npm global packages
  upstream  Install upstream CLI tools
  flatpak   Install Flatpak apps
  services  Enable user/system services
  nginx     Configure host nginx reverse proxy
  gnome     Apply GNOME settings when GNOME is detected
EOF
}

run_section() {
  case "$1" in
    all) run_all ;;
    packages) install_fedora_packages; install_apt_packages ;;
    go) install_go_tools ;;
    shell) install_oh_my_zsh ;;
    npm) install_npm_packages ;;
    upstream) install_extra_cli_tools ;;
    flatpak | flatpaks) install_flatpaks ;;
    services) enable_services ;;
    nginx) configure_nginx_proxy ;;
    gnome) apply_gnome_settings ;;
    help | -h | --help) usage ;;
    *)
      printf 'Unknown bootstrap section: %s\n\n' "$1" >&2
      usage >&2
      exit 2
      ;;
  esac
}

main() {
  if [[ "${1:-}" == "help" || "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
    usage
    return 0
  fi

  echo "Running bootstrap..."

  if [[ $# -eq 0 ]]; then
    run_all
  else
    for section in "$@"; do
      run_section "$section"
    done
  fi

  print_post_setup_notes
  echo "Bootstrap complete."
}

main "$@"
