ensure_env_permissions() {
  local mode

  [[ -f "$env_file" ]] || return 0

  mode="$(stat -c '%a' "$env_file" 2>/dev/null || true)"
  [[ -n "$mode" ]] || return 0

  if (( (8#$mode & 077) != 0 )); then
    warn "$env_file is mode $mode; tightening to 600"
    run_cmd chmod 600 "$env_file"
  fi
}

load_homelab_env() {
  local required="${1:-required}"

  if [[ ! -f "$env_file" ]]; then
    [[ "$required" == "optional" ]] && return 0
    die "Missing $env_file. Copy homelab/.env.example to homelab/.env and set PIHOLE_PASSWORD."
  fi

  ensure_env_permissions
  set -a
  source "$env_file"
  set +a
}

require_env() {
  local name="$1"
  [[ -n "${!name:-}" ]] || die "$name must be set in $env_file"
}

validate_csv_labels() {
  local name="$1" value="$2" label

  value="${value//,/ }"
  for label in $value; do
    label="$(trim_spaces "$label")"
    [[ -n "$label" ]] || continue
    valid_label "$label" || die "Invalid DNS name in $name: $label"
  done
}

validate_homelab_apps() {
  local apps="${HOMELAB_APPS:-glance}" app app_dir

  apps="${apps//,/ }"
  for app in $apps; do
    app="$(trim_spaces "$app")"
    [[ -n "$app" && "$app" != "pi-hole" ]] || continue

    valid_name "$app" || die "Invalid app name in HOMELAB_APPS: $app"

    app_dir="$apps_dir/$app"
    [[ -f "$app_dir/docker-compose.yml" ]] || die "Unknown homelab app: $app"
  done
}

validate_homelab_env() {
  local name value

  validate_homelab_apps

  case "${HOMELAB_ACCESS_MODE:-lan}" in
    lan | tailscale-only) ;;
    *) die "Invalid HOMELAB_ACCESS_MODE: ${HOMELAB_ACCESS_MODE:-}" ;;
  esac

  [[ "${PIHOLE_PASSWORD:-}" != "change_me_to_a_strong_password" ]] || die "PIHOLE_PASSWORD still uses the example value"

  for name in HOMELAB_IP DHCP_START DHCP_END DHCP_ROUTER; do
    value="${!name:-}"
    [[ -z "$value" ]] || valid_ipv4 "$value" || die "Invalid $name: $value"
  done

  for name in PIHOLE_DOMAIN HOMELAB_DOMAIN; do
    value="${!name:-}"
    [[ -z "$value" ]] || valid_domain "$value" || die "Invalid $name: $value"
  done

  for name in HOMELAB_DNS_NAMES HOMELAB_TAILNET_DNS_NAMES; do
    value="${!name:-}"
    [[ -z "$value" ]] || validate_csv_labels "$name" "$value"
  done

  value="${HOMELAB_TAILNET_DNS_SUFFIX:-}"
  [[ -z "$value" ]] || valid_label "$value" || die "Invalid HOMELAB_TAILNET_DNS_SUFFIX: $value"

  for name in DHCP_ACTIVE HOMELAB_ENABLE_PIHOLE_DNS; do
    value="${!name:-}"
    [[ -z "$value" ]] || valid_bool "$value" || die "Invalid $name: $value"
  done

  if tailscale_only_mode; then
    [[ -n "${DHCP_ACTIVE:-}" ]] || die "DHCP_ACTIVE=false must be set when HOMELAB_ACCESS_MODE=tailscale-only"
    ! truthy "$DHCP_ACTIVE" || die "DHCP_ACTIVE=false is required when HOMELAB_ACCESS_MODE=tailscale-only"
    require_tailscale_access
  fi
}

validate_pihole_env() {
  require_env PIHOLE_PASSWORD
  validate_homelab_env
}
