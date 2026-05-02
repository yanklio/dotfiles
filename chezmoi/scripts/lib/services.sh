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
  local root config_dir
  have nginx || [[ -x /usr/sbin/nginx || -x /usr/bin/nginx ]] || return 0
  root="$(dotfiles_root)" || return 0
  config_dir="$root/homelab/services/nginx/conf.d"
  [[ -d "$config_dir" ]] || return 0

  echo "Configuring nginx reverse proxy..."
  as_root bash -c '
    set -euo pipefail
    config_dir="$1"
    mkdir -p /etc/nginx/conf.d

    if [[ -L /etc/nginx/sites-enabled/default ]]; then
      rm /etc/nginx/sites-enabled/default
    elif [[ -e /etc/nginx/sites-enabled/default ]]; then
      mv -n /etc/nginx/sites-enabled/default /etc/nginx/sites-available/default.disabled
    fi

    for site in /etc/nginx/conf.d/default.conf /etc/nginx/conf.d/welcome.conf; do
      [[ -e "$site" ]] || continue
      mv -n "$site" "$site.disabled"
    done

    rm -f /etc/nginx/conf.d/home-lab.conf /etc/nginx/conf.d/dotfiles-*.conf
    for conf in "$config_dir"/*.conf; do
      [[ -e "$conf" ]] || continue
      rm -f "/etc/nginx/conf.d/$(basename "$conf")"
      install -m 0644 "$conf" "/etc/nginx/conf.d/dotfiles-$(basename "$conf")"
    done
  ' bash "$config_dir" || {
    echo "No TTY available for sudo; skipping nginx reverse proxy setup."
    add_post_setup_note "Nginx: run 'bash ~/Dotfiles/chezmoi/scripts/bootstrap.sh nginx' from an interactive shell."
    return 0
  }

  as_root nginx -t || return 1
  as_root systemctl enable --now nginx
  as_root systemctl reload nginx
}
