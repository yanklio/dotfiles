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
  enabled "${DOTFILES_DRY_RUN:-}"
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
  elif [[ -t 0 ]] && have sudo; then
    run_cmd sudo "$@"
  else
    return 1
  fi
}

add_post_setup_note() {
  local note="$1"
  [[ -n "$note" ]] || return 0
  post_setup_notes+=("$note")
}

dotfiles_root() {
  local root
  root="$(cd "$script_dir/../.." && pwd)"
  [[ -d "$root/homelab" ]] || return 1
  printf '%s\n' "$root"
}

read_list() {
  local file="$1" line
  [[ -r "$file" ]] || return 0

  while IFS= read -r line || [[ -n "$line" ]]; do
    [[ "$line" =~ ^[[:space:]]*(#|$) ]] && continue
    printf '%s\n' "$line"
  done < "$file"
}

detect_package_manager() {
  if have dnf; then
    printf '%s\n' dnf
  elif have apt-get; then
    printf '%s\n' apt
  else
    return 1
  fi
}

is_homelab_server() {
  case "${DOTFILES_HOMELAB_SERVER:-}" in
    1 | true | yes | on) return 0 ;;
    0 | false | no | off) return 1 ;;
  esac

  case "${DOTFILES_MACHINE_ROLE:-client}" in
    server | homelab-server) return 0 ;;
    *) return 1 ;;
  esac
}

is_gnome() {
  case "${DOTFILES_GNOME_SETTINGS:-auto}" in
    1 | true | yes | on | force | gnome) return 0 ;;
    0 | false | no | off | none | skip) return 1 ;;
  esac

  local desktop="${XDG_CURRENT_DESKTOP:-}:${XDG_SESSION_DESKTOP:-}:${DESKTOP_SESSION:-}"
  [[ "${desktop,,}" == *gnome* ]]
}

print_post_setup_notes() {
  [[ ${#post_setup_notes[@]} -gt 0 ]] || return 0

  echo
  echo "Post-setup notes:"
  for note in "${post_setup_notes[@]}"; do
    echo "- $note"
  done
}
