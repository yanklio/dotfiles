#!/usr/bin/env bash
set -euo pipefail

dotfiles_repo="${DOTFILES_REPO:-https://github.com/yanklio/dotfiles.git}"
dotfiles_dir="${DOTFILES_DIR:-$HOME/Dotfiles}"
machine_role="${DOTFILES_MACHINE_ROLE:-client}"
gnome_settings="${DOTFILES_GNOME_SETTINGS:-auto}"
distro="auto"
package_manager=""

export PATH="$HOME/.local/bin:$PATH"

usage() {
  cat <<EOF
Usage: $0 [options]

Options:
  --server           Configure this machine as a homelab server before first apply
  --client           Configure this machine as a client/workstation (default)
  --gnome            Force GNOME settings during bootstrap
  --no-gnome         Skip GNOME settings during bootstrap
  --repo URL         Clone from URL (default: $dotfiles_repo)
  --dir PATH         Clone to PATH (default: $dotfiles_dir)
  --distro NAME      Force package setup for auto, fedora, or debian
  -h, --help         Show this help
EOF
}

have() {
  command -v "$1" >/dev/null 2>&1
}

as_root() {
  if [[ $EUID -eq 0 ]]; then
    "$@"
  else
    have sudo || {
      echo "sudo is required" >&2
      exit 1
    }
    sudo "$@"
  fi
}

parse_args() {
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --server) machine_role="server" ;;
      --client | --workstation) machine_role="client" ;;
      --gnome) gnome_settings="on" ;;
      --no-gnome) gnome_settings="off" ;;
      --fedora) distro="fedora" ;;
      --debian | --ubuntu) distro="debian" ;;
      --distro)
        [[ $# -ge 2 ]] || { echo "--distro requires a value" >&2; exit 2; }
        distro="$2"
        shift
        ;;
      --distro=*) distro="${1#*=}" ;;
      --repo)
        [[ $# -ge 2 ]] || { echo "--repo requires a value" >&2; exit 2; }
        dotfiles_repo="$2"
        shift
        ;;
      --repo=*) dotfiles_repo="${1#*=}" ;;
      --dir)
        [[ $# -ge 2 ]] || { echo "--dir requires a value" >&2; exit 2; }
        dotfiles_dir="$2"
        shift
        ;;
      --dir=*) dotfiles_dir="${1#*=}" ;;
      -h | --help) usage; exit 0 ;;
      *) echo "Unknown option: $1" >&2; usage >&2; exit 2 ;;
    esac
    shift
  done
}

detect_package_manager() {
  case "$distro" in
    auto) ;;
    fedora) package_manager="dnf"; return 0 ;;
    debian | ubuntu) package_manager="apt-get"; return 0 ;;
    *) echo "Unsupported distro: $distro" >&2; exit 2 ;;
  esac

  if have dnf; then
    package_manager="dnf"
  elif have apt-get; then
    package_manager="apt-get"
  else
    echo "Neither dnf nor apt-get is available" >&2
    exit 1
  fi
}

install_base_packages() {
  detect_package_manager

  echo "Installing base packages..."
  case "$package_manager" in
    dnf)
      as_root dnf install -y git curl ca-certificates
      ;;
    apt-get)
      as_root apt-get update
      as_root apt-get install -y git curl ca-certificates
      ;;
  esac
}

install_chezmoi() {
  have chezmoi && return 0

  echo "Installing chezmoi..."
  sh -c "$(curl -fsLS get.chezmoi.io)" -- -b "$HOME/.local/bin"
}

clone_dotfiles() {
  if [[ -d "$dotfiles_dir/.git" ]]; then
    echo "Updating existing dotfiles repo..."
    git -C "$dotfiles_dir" pull --ff-only
    return 0
  fi

  if [[ -e "$dotfiles_dir" ]]; then
    echo "Refusing to overwrite existing path: $dotfiles_dir" >&2
    exit 1
  fi

  echo "Cloning dotfiles..."
  git clone "$dotfiles_repo" "$dotfiles_dir"
}

write_chezmoi_data() {
  local config tmp
  config="$HOME/.config/chezmoi/chezmoi.toml"

  mkdir -p "$HOME/.config/chezmoi"
  tmp="$(mktemp)"

  if [[ -f "$config" ]]; then
    awk -v role="$machine_role" -v gnome="$gnome_settings" '
      /^\[data\][[:space:]]*$/ { in_data = 1; saw_data = 1; print; next }
      /^\[/ {
        if (in_data) {
          if (!wrote_role) print "  machineRole = \"" role "\""
          if (!wrote_gnome) print "  gnomeSettings = \"" gnome "\""
        }
        in_data = 0
      }
      in_data && /^[[:space:]]*machineRole[[:space:]]*=/ {
        if (!wrote_role) print "  machineRole = \"" role "\""
        wrote_role = 1
        next
      }
      in_data && /^[[:space:]]*gnomeSettings[[:space:]]*=/ {
        if (!wrote_gnome) print "  gnomeSettings = \"" gnome "\""
        wrote_gnome = 1
        next
      }
      { print }
      END {
        if (!saw_data) {
          print ""
          print "[data]"
          print "  machineRole = \"" role "\""
          print "  gnomeSettings = \"" gnome "\""
        } else if (in_data) {
          if (!wrote_role) print "  machineRole = \"" role "\""
          if (!wrote_gnome) print "  gnomeSettings = \"" gnome "\""
        }
      }
    ' "$config" > "$tmp"
  else
    cat > "$tmp" <<EOF
[data]
  machineRole = "$machine_role"
  gnomeSettings = "$gnome_settings"
EOF
  fi

  mv "$tmp" "$config"
}

apply_dotfiles() {
  local chezmoi_source="$dotfiles_dir/chezmoi"

  export DOTFILES_MACHINE_ROLE="$machine_role"
  export DOTFILES_GNOME_SETTINGS="$gnome_settings"

  echo "Initializing chezmoi..."
  chezmoi init --source="$chezmoi_source"

  echo "Applying dotfiles..."
  chezmoi apply
}

run_bootstrap() {
  local bootstrap="$dotfiles_dir/chezmoi/scripts/bootstrap.sh"

  [[ -x "$bootstrap" ]] || {
    echo "Bootstrap script not found or not executable: $bootstrap" >&2
    exit 1
  }

  export DOTFILES_MACHINE_ROLE="$machine_role"
  export DOTFILES_GNOME_SETTINGS="$gnome_settings"

  echo "Running bootstrap..."
  "$bootstrap"
}

main() {
  parse_args "$@"
  install_base_packages
  install_chezmoi
  clone_dotfiles
  write_chezmoi_data
  apply_dotfiles
  run_bootstrap
}

main "$@"
