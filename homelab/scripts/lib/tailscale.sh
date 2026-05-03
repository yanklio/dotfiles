homelab_access_mode() {
  printf '%s\n' "${HOMELAB_ACCESS_MODE:-lan}"
}

tailscale_only_mode() {
  [[ "$(homelab_access_mode)" == "tailscale-only" ]]
}

tailscale_ipv4() {
  tailscale ip -4 2>/dev/null | while IFS= read -r ip; do
    [[ -n "$ip" ]] || continue
    valid_ipv4 "$ip" || continue
    printf '%s\n' "$ip"
    return 0
  done
}

require_tailscale_access() {
  local ip

  require tailscale
  tailscale status >/dev/null 2>&1 || die "Tailscale is not running or this host is not logged in; run 'tailscale up' first."

  ip="$(tailscale_ipv4)"
  [[ -n "$ip" ]] || die "No Tailscale IPv4 address found; check 'tailscale status' and 'tailscale ip -4'."
}

show_tailscale_access_urls() {
  local ip host
  tailscale_only_mode || return 0

  ip="$(tailscale_ipv4)"
  [[ -n "$ip" ]] || return 0
  host="$(hostname -s 2>/dev/null || hostname 2>/dev/null || true)"

  echo "Tailscale access:"
  echo "  http://$ip/"
  [[ -n "$host" ]] && echo "  http://$host/ (with Tailscale MagicDNS)"
}
