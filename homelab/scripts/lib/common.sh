have() {
  command -v "$1" >/dev/null 2>&1
}

enabled() {
  case "${1:-}" in
    1 | true | yes | on) return 0 ;;
    *) return 1 ;;
  esac
}

dry_run() {
  enabled "${HOMELAB_DRY_RUN:-${DOTFILES_DRY_RUN:-}}"
}

die() {
  echo "$*" >&2
  exit 1
}

warn() {
  echo "Warning: $*" >&2
}

run_cmd() {
  if dry_run; then
    printf '+ '
    printf '%q ' "$@"
    printf '\n'
    return 0
  fi

  "$@"
}

as_root() {
  if dry_run; then
    run_cmd "$@"
    return 0
  fi

  if [[ $EUID -eq 0 ]]; then
    run_cmd "$@"
  elif have sudo; then
    run_cmd sudo "$@"
  else
    return 1
  fi
}

require() {
  have "$1" || die "$1 is required"
}

require_podman_compose() {
  require podman
  podman compose version >/dev/null 2>&1 || die "podman compose is required"
}

trim_spaces() {
  local value="$1"
  value="${value#"${value%%[![:space:]]*}"}"
  value="${value%"${value##*[![:space:]]}"}"
  printf '%s\n' "$value"
}

valid_name() {
  [[ "$1" =~ ^[A-Za-z0-9._-]+$ ]]
}

valid_label() {
  [[ "$1" =~ ^[A-Za-z0-9]([A-Za-z0-9-]{0,61}[A-Za-z0-9])?$ ]]
}

valid_domain() {
  local domain="$1" label
  local -a labels
  [[ -n "$domain" && ${#domain} -le 253 ]] || return 1
  IFS='.' read -ra labels <<< "$domain"
  for label in "${labels[@]}"; do
    valid_label "$label" || return 1
  done
}

valid_ipv4() {
  local ip="$1" octet
  local -a octets
  [[ "$ip" =~ ^([0-9]{1,3}\.){3}[0-9]{1,3}$ ]] || return 1
  IFS='.' read -ra octets <<< "$ip"
  for octet in "${octets[@]}"; do
    [[ "$octet" =~ ^[0-9]+$ ]] || return 1
    (( 10#$octet >= 0 && 10#$octet <= 255 )) || return 1
  done
}

truthy() {
  case "${1:-}" in
    1 | true | yes | on) return 0 ;;
    0 | false | no | off | '') return 1 ;;
    *) return 2 ;;
  esac
}
