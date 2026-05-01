#!/usr/bin/env bash
set -euo pipefail

dotfiles_dir="${DOTFILES_DIR:-$HOME/Dotfiles}"
package="chezmoi"
source="$dotfiles_dir/$package/.local/share/chezmoi"
target="$HOME/.local/share/chezmoi"

command -v stow >/dev/null 2>&1 || {
  echo "stow is not installed" >&2
  exit 1
}

[ -d "$source" ] || {
  echo "chezmoi source not found: $source" >&2
  exit 1
}

mkdir -p "$(dirname "$target")"

if [ -L "$target" ] && [ "$(readlink -f "$target")" = "$(readlink -f "$source")" ]; then
  stow --dir="$dotfiles_dir" --target="$HOME" --restow "$package"
  echo "chezmoi is already stowed"
  exit 0
fi

if [ -e "$target" ] || [ -L "$target" ]; then
  backup="$target.backup.$(date +%Y%m%d%H%M%S)"
  mv "$target" "$backup"
  echo "Moved existing chezmoi source to $backup"
fi

stow --dir="$dotfiles_dir" --target="$HOME" "$package"
echo "Stowed $target -> $source"
