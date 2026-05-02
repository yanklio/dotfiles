has_role() {
  local roles="$1"

  [[ ",$roles," == *,all,* ]] && return 0
  [[ ",$roles," == *,core,* ]] && return 0
  [[ ",$roles," == *,dev,* ]] && return 0
  is_gnome && [[ ",$roles," == *,desktop,* ]] && return 0
  is_homelab_server && [[ ",$roles," == *,server,* ]] && return 0

  return 1
}

supports_package_manager() {
  local package_manager="$1" managers="$2"
  [[ ",$managers," == *,all,* || ",$managers," == *,"$package_manager",* ]]
}

collect_packages() {
  local package_manager="$1" package roles managers

  while IFS='|' read -r package roles managers; do
    [[ -n "${package:-}" && "$package" != \#* ]] || continue
    roles="${roles:-all}"
    managers="${managers:-all}"

    has_role "$roles" || continue
    supports_package_manager "$package_manager" "$managers" || continue
    printf '%s\n' "$package"
  done < "$packages_dir/system.txt"
}

install_system_packages() {
  local package_manager packages
  package_manager="$(detect_package_manager)" || return 0

  mapfile -t packages < <(collect_packages "$package_manager" | sort -u)
  [[ ${#packages[@]} -gt 0 ]] || return 0

  echo "Installing system packages..."
  case "$package_manager" in
    dnf)
      as_root dnf install -y "${packages[@]}" \
        || echo "No TTY available for sudo; skipping Fedora packages."
      ;;
    apt)
      as_root apt-get update \
        && as_root apt-get install -y "${packages[@]}" \
        || echo "No TTY available for sudo; skipping Debian/Ubuntu packages."
      ;;
  esac
}
