ensure_env_permissions() {
  [[ -f "$env_file" ]] || return 0

  local mode
  mode="$(stat -c '%a' "$env_file" 2>/dev/null || true)"
  [[ -n "$mode" ]] || return 0

  if (( (8#$mode & 077) != 0 )); then
    warn "$env_file is mode $mode; tightening to 600"
    run_cmd chmod 600 "$env_file"
  fi
}

load_homelab_env() {
  local required="${1:-required}" line key value quote

  if [[ ! -f "$env_file" ]]; then
    [[ "$required" == "optional" ]] && return 0
    die "Missing $env_file. Copy homelab/.env.example to homelab/.env and set PIHOLE_PASSWORD."
  fi

  ensure_env_permissions

  while IFS= read -r line || [[ -n "$line" ]]; do
    line="$(trim_spaces "$line")"
    [[ "$line" =~ ^(#|$) ]] && continue
    [[ "$line" == export\ * ]] && line="$(trim_spaces "${line#export }")"
    [[ "$line" == *=* ]] || die "Invalid line in $env_file: $line"

    key="$(trim_spaces "${line%%=*}")"
    value="$(trim_spaces "${line#*=}")"
    [[ "$key" =~ ^[A-Za-z_][A-Za-z0-9_]*$ ]] || die "Invalid key in $env_file: $key"

    quote="${value:0:1}"
    if [[ "$quote" == "'" || "$quote" == '"' ]]; then
      [[ "${value: -1}" == "$quote" ]] || die "Unclosed quoted value in $env_file for $key"
      value="${value:1:${#value}-2}"
    fi

    export "$key=$value"
  done < "$env_file"

  HOMELAB_ENV_LOADED=1
}

require_env() {
  local name="$1"
  [[ -n "${!name:-}" ]] || die "$name must be set in $env_file"
}

validate_csv_labels() {
  local value="$1" label
  value="${value//,/ }"
  for label in $value; do
    label="$(trim_spaces "$label")"
    [[ -n "$label" ]] || continue
    valid_label "$label" || die "Invalid DNS name in HOMELAB_DNS_NAMES: $label"
  done
}

validate_homelab_apps() {
  local apps="${HOMELAB_APPS:-glance}" app app_dir
  apps="${apps//,/ }"

  for app in $apps; do
    app="$(trim_spaces "$app")"
    [[ -n "$app" ]] || continue
    valid_name "$app" || die "Invalid app name in HOMELAB_APPS: $app"
    [[ "$app" == "pi-hole" ]] && continue
    app_dir="$apps_dir/$app"
    [[ -f "$app_dir/docker-compose.yml" ]] || die "Unknown homelab app: $app"
  done
}

validate_homelab_env() {
  validate_homelab_apps

  case "$(homelab_access_mode)" in
    lan | tailscale-only) ;;
    *) die "Invalid HOMELAB_ACCESS_MODE: $(homelab_access_mode)" ;;
  esac

  if [[ -n "${PIHOLE_PASSWORD:-}" && "$PIHOLE_PASSWORD" == "change_me_to_a_strong_password" ]]; then
    die "PIHOLE_PASSWORD still uses the example value"
  fi

  [[ -z "${HOMELAB_IP:-}" ]] || valid_ipv4 "$HOMELAB_IP" || die "Invalid HOMELAB_IP: $HOMELAB_IP"
  [[ -z "${DHCP_START:-}" ]] || valid_ipv4 "$DHCP_START" || die "Invalid DHCP_START: $DHCP_START"
  [[ -z "${DHCP_END:-}" ]] || valid_ipv4 "$DHCP_END" || die "Invalid DHCP_END: $DHCP_END"
  [[ -z "${DHCP_ROUTER:-}" ]] || valid_ipv4 "$DHCP_ROUTER" || die "Invalid DHCP_ROUTER: $DHCP_ROUTER"
  [[ -z "${PIHOLE_DOMAIN:-}" ]] || valid_domain "$PIHOLE_DOMAIN" || die "Invalid PIHOLE_DOMAIN: $PIHOLE_DOMAIN"
  [[ -z "${HOMELAB_DOMAIN:-}" ]] || valid_domain "$HOMELAB_DOMAIN" || die "Invalid HOMELAB_DOMAIN: $HOMELAB_DOMAIN"
  [[ -z "${HOMELAB_DNS_NAMES:-}" ]] || validate_csv_labels "$HOMELAB_DNS_NAMES"

  if [[ -n "${DHCP_ACTIVE:-}" ]]; then
    valid_bool "$DHCP_ACTIVE" || die "Invalid DHCP_ACTIVE: $DHCP_ACTIVE"
  fi

  if tailscale_only_mode; then
    [[ -n "${DHCP_ACTIVE:-}" ]] || die "DHCP_ACTIVE=false must be set when HOMELAB_ACCESS_MODE=tailscale-only"
    truthy "$DHCP_ACTIVE" && die "DHCP_ACTIVE=false is required when HOMELAB_ACCESS_MODE=tailscale-only"
    require_tailscale_access
  fi
}

validate_pihole_env() {
  require_env PIHOLE_PASSWORD
  validate_homelab_env
}
