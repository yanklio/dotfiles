install_go_tools() {
  have go || return 0

  local tools tool
  mapfile -t tools < <(read_list "$packages_dir/go.txt")
  [[ ${#tools[@]} -gt 0 ]] || return 0

  echo "Installing Go tools..."
  for tool in "${tools[@]}"; do
    run_cmd go install "$tool"
  done
}

install_oh_my_zsh() {
  have curl || return 0
  [[ ! -d "$HOME/.oh-my-zsh" ]] || return 0

  echo "Installing oh-my-zsh..."
  if dry_run; then
    echo '+ curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh | sh --unattended'
    return 0
  fi

  RUNZSH=no CHSH=no KEEP_ZSHRC=yes sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
}

install_npm_packages() {
  have npm || return 0

  local packages
  mapfile -t packages < <(read_list "$packages_dir/npm.txt")
  [[ ${#packages[@]} -gt 0 ]] || return 0

  echo "Installing npm packages..."
  run_cmd npm install --global --prefix "$HOME/.local" "${packages[@]}"
}

install_extra_cli_tools() {
  have curl || return 0

  local command_name display_name install_url
  while IFS='|' read -r command_name display_name install_url; do
    [[ -n "$command_name" && -n "$display_name" && -n "$install_url" ]] || continue
    have "$command_name" && continue

    echo "Installing $display_name..."
    if dry_run; then
      printf '+ curl -fsSL %q | sh\n' "$install_url"
    else
      curl -fsSL "$install_url" | sh
    fi

    case "$command_name" in
      tailscale)
        add_post_setup_note "Tailscale: run 'sudo tailscale up' to complete setup."
        ;;
    esac
  done < <(read_list "$packages_dir/upstream.txt")
}

install_flatpaks() {
  have flatpak || return 0

  local apps app
  mapfile -t apps < <(read_list "$packages_dir/flatpak.txt")
  [[ ${#apps[@]} -gt 0 ]] || return 0

  echo "Installing Flatpaks..."
  for app in "${apps[@]}"; do
    flatpak info "$app" >/dev/null 2>&1 && continue
    run_cmd flatpak install --noninteractive --user -y flathub "$app" 2>/dev/null \
      || run_cmd flatpak install --noninteractive --system -y flathub "$app" 2>/dev/null \
      || echo "Skipping $app; install manually if needed."
  done
}
