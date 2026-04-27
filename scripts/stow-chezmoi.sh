#!/usr/bin/env bash
set -euo pipefail

home_dir="${HOME:?HOME is not set}"
dotfiles_dir="${DOTFILES_DIR:-$home_dir/Dotfiles}"
package_name="${PACKAGE_NAME:-chezmoi}"
chezmoi_source="${CHEZMOI_SOURCE:-$home_dir/.local/share/chezmoi}"
package_source="$dotfiles_dir/$package_name/.local/share/chezmoi"
backup_path="$chezmoi_source.backup.$(date +%Y%m%d%H%M%S)"

require_command() {
  if ! command -v "$1" >/dev/null 2>&1; then
    printf 'Missing required command: %s\n' "$1" >&2
    exit 1
  fi
}

require_command stow
require_command rsync

mkdir -p "$(dirname "$package_source")"

if [ -L "$chezmoi_source" ]; then
  current_target="$(readlink "$chezmoi_source")"
  current_resolved="$(readlink -f "$chezmoi_source")"
  package_resolved="$(readlink -f "$package_source")"
  if [ "$current_resolved" = "$package_resolved" ]; then
    stow --dir="$dotfiles_dir" --target="$home_dir" --restow "$package_name"
    printf 'chezmoi is already stowed from %s\n' "$package_source"
    exit 0
  fi

  printf 'Refusing to replace existing symlink: %s -> %s\n' "$chezmoi_source" "$current_target" >&2
  exit 1
fi

if [ ! -d "$chezmoi_source" ]; then
  printf 'chezmoi source directory not found: %s\n' "$chezmoi_source" >&2
  exit 1
fi

rsync -a --delete "$chezmoi_source/" "$package_source/"

mv "$chezmoi_source" "$backup_path"

if ! stow --dir="$dotfiles_dir" --target="$home_dir" "$package_name"; then
  rm -f "$chezmoi_source"
  mv "$backup_path" "$chezmoi_source"
  printf 'stow failed; restored original chezmoi source from backup.\n' >&2
  exit 1
fi

if [ ! -L "$chezmoi_source" ] || [ "$(readlink -f "$chezmoi_source")" != "$(readlink -f "$package_source")" ]; then
  rm -f "$chezmoi_source"
  mv "$backup_path" "$chezmoi_source"
  printf 'stow verification failed; restored original chezmoi source from backup.\n' >&2
  exit 1
fi

rm -rf "$backup_path"
printf 'Stowed chezmoi source: %s -> %s\n' "$chezmoi_source" "$package_source"
