#!/usr/bin/env bash
set -euo pipefail

dotfiles_dir="${DOTFILES_DIR:-$HOME/Dotfiles}"
chezmoi_source="$dotfiles_dir/chezmoi"
homelab_dir="$dotfiles_dir/homelab"
env_file="$homelab_dir/.env"

have() {
  command -v "$1" >/dev/null 2>&1
}

require_sudo() {
  if [[ $EUID -eq 0 ]]; then
    return 0
  fi

  have sudo || {
    echo "sudo is required" >&2
    exit 1
  }
}

install_base_packages() {
  export PATH="$HOME/.local/bin:$PATH"

  have apt-get || return 0

  echo "Installing base packages..."
  sudo apt-get update
  sudo apt-get install -y git curl

  if ! have chezmoi; then
    echo "Installing chezmoi..."
    sh -c "$(curl -fsLS get.chezmoi.io)" -- -b "$HOME/.local/bin"
  fi
}

detect_ip() {
  ip -4 route get 1.1.1.1 2>/dev/null | tr ' ' '\n' | awk 'prev == "src" { print; exit } { prev = $0 }'
}

detect_gateway() {
  ip -4 route show default 2>/dev/null | awk '{ print $3; exit }'
}

network_prefix() {
  local ip="$1"
  printf '%s.%s.%s' ${ip//./ }
}

write_server_role() {
  local config tmp

  config="$HOME/.config/chezmoi/chezmoi.toml"
  mkdir -p "$HOME/.config/chezmoi"

  if [[ ! -f "$config" ]]; then
    cat > "$config" <<'EOF'
[data]
  machineRole = "server"
EOF
    return 0
  fi

  tmp="$(mktemp)"
  awk '
    /^\[data\][[:space:]]*$/ { in_data = 1; saw_data = 1; print; next }
    /^\[/ {
      if (in_data && !wrote_role) {
        print "  machineRole = \"server\""
        wrote_role = 1
      }
      in_data = 0
    }
    in_data && /^[[:space:]]*machineRole[[:space:]]*=/ {
      if (!wrote_role) {
        print "  machineRole = \"server\""
        wrote_role = 1
      }
      next
    }
    { print }
    END {
      if (!saw_data) {
        print ""
        print "[data]"
        print "  machineRole = \"server\""
      } else if (in_data && !wrote_role) {
        print "  machineRole = \"server\""
      }
    }
  ' "$config" > "$tmp"
  mv "$tmp" "$config"
}

ensure_homelab_env() {
  if [[ -f "$env_file" ]]; then
    echo "Using existing $env_file"
    return 0
  fi

  local ip gateway prefix password
  ip="$(detect_ip)"
  gateway="$(detect_gateway)"

  [[ -n "$ip" ]] || read -rp "Homelab server IP: " ip
  [[ -n "$gateway" ]] || read -rp "Router/gateway IP: " gateway

  prefix="$(network_prefix "$ip")"

  read -rsp "Pi-hole admin password: " password
  echo

  cat > "$env_file" <<EOF
PIHOLE_PASSWORD=$password
DHCP_ACTIVE=true
DHCP_START=$prefix.100
DHCP_END=$prefix.200
DHCP_ROUTER=$gateway
DHCP_LEASE_TIME=24h
PIHOLE_DOMAIN=home
HOMELAB_IP=$ip
HOMELAB_DOMAIN=home
HOMELAB_DNS_NAMES=pihole,glance
EOF
}

main() {
  require_sudo

  [[ -d "$dotfiles_dir" ]] || {
    echo "Dotfiles repo not found: $dotfiles_dir" >&2
    exit 1
  }

  install_base_packages
  write_server_role

  chezmoi init --source="$chezmoi_source"
  chezmoi apply

  ensure_homelab_env
  bash "$homelab_dir/scripts/start-all.sh"
  "$chezmoi_source/scripts/bootstrap.sh" nginx

  echo "Homelab server install complete."
  echo "Verify: nslookup glance.home $(grep '^HOMELAB_IP=' "$env_file" | cut -d= -f2-)"
}

main "$@"
