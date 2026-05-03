nginx_listen_address() {
  if tailscale_only_mode; then
    printf '%s:80\n' "$(tailscale_ipv4)"
  else
    printf '80\n'
  fi
}

configure_homelab_nginx() {
  local config_dir="$homelab_dir/services/nginx/conf.d" listen tmp_dir conf rendered site line

  [[ -d "$config_dir" ]] || die "Missing nginx config directory: $config_dir"

  load_homelab_env optional
  validate_homelab_env
  listen="$(nginx_listen_address)"

  if dry_run; then
    run_cmd install -m 0644 "$config_dir"/*.conf /etc/nginx/conf.d/
    echo "Nginx reverse proxy listening on $listen."
    return 0
  fi

  tmp_dir="$(mktemp -d)"

  for conf in "$config_dir"/*.conf; do
    [[ -e "$conf" ]] || continue
    rendered="$tmp_dir/dotfiles-$(basename "$conf")"
    while IFS= read -r line || [[ -n "$line" ]]; do
      case "$line" in
        *'listen 80 default_server;'*)
          printf '%s\n' "${line/listen 80 default_server;/listen $listen default_server;}"
          ;;
        *)
          printf '%s\n' "${line/listen 80;/listen $listen;}"
          ;;
      esac
    done < "$conf" > "$rendered"
  done

  as_root mkdir -p /etc/nginx/conf.d

  if [[ -L /etc/nginx/sites-enabled/default ]]; then
    as_root rm /etc/nginx/sites-enabled/default
  elif [[ -e /etc/nginx/sites-enabled/default ]]; then
    as_root mv -n /etc/nginx/sites-enabled/default /etc/nginx/sites-available/default.disabled
  fi

  for site in /etc/nginx/conf.d/default.conf /etc/nginx/conf.d/welcome.conf; do
    [[ -e "$site" ]] && as_root mv -n "$site" "$site.disabled"
  done

  as_root rm -f /etc/nginx/conf.d/home-lab.conf /etc/nginx/conf.d/dotfiles-*.conf
  for rendered in "$tmp_dir"/*.conf; do
    [[ -e "$rendered" ]] || continue
    as_root install -m 0644 "$rendered" "/etc/nginx/conf.d/$(basename "$rendered")"
  done

  rm -rf "$tmp_dir"

  as_root nginx -t
  as_root systemctl enable --now nginx
  as_root systemctl reload nginx

  echo "Nginx reverse proxy listening on $listen."
}
