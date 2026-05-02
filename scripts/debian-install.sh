#!/usr/bin/env bash
set -euo pipefail

script_path="${BASH_SOURCE[0]:-}"
if [[ -n "$script_path" && -f "$script_path" ]]; then
  script_dir="$(cd "$(dirname "$script_path")" && pwd)"
  if [[ -f "$script_dir/install.sh" ]]; then
    exec bash "$script_dir/install.sh" --distro debian "$@"
  fi
fi

raw_base="${DOTFILES_RAW_BASE:-https://raw.githubusercontent.com/yanklio/dotfiles/main}"
curl -fsSL "$raw_base/scripts/install.sh" | bash -s -- --distro debian "$@"
