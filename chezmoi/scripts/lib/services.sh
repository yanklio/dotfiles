enable_services() {
  have systemctl || return 0

  if have ollama; then
    echo "Enabling ollama service..."
    run_cmd systemctl --user enable --now ollama 2>/dev/null \
      || as_root systemctl enable --now ollama \
      || echo "Warning: could not enable ollama service"
  fi

  if have podman; then
    echo "Enabling podman.socket..."
    run_cmd systemctl --user enable --now podman.socket 2>/dev/null \
      || as_root systemctl enable --now podman.socket \
      || echo "Warning: could not enable podman.socket"
  fi
}

configure_nginx_proxy() {
  local root homelab
  have nginx || [[ -x /usr/sbin/nginx || -x /usr/bin/nginx ]] || return 0
  root="$(dotfiles_root)" || return 0
  homelab="$root/homelab/scripts/homelab.sh"
  [[ -x "$homelab" ]] || return 0

  echo "Configuring nginx reverse proxy..."
  "$homelab" nginx || {
    echo "No TTY available for sudo; skipping nginx reverse proxy setup."
    add_post_setup_note "Nginx: run 'bash ~/Dotfiles/chezmoi/scripts/bootstrap.sh nginx' from an interactive shell."
    return 0
  }
}
