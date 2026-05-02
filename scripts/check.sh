#!/usr/bin/env bash
set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

have() {
  command -v "$1" >/dev/null 2>&1
}

check_shell() {
  echo "Checking shell syntax..."
  bash -n "$root"/scripts/*.sh
  bash -n "$root"/homelab/scripts/*.sh
  bash -n "$root/chezmoi/scripts/bootstrap.sh"
  bash -n "$root"/chezmoi/scripts/lib/*.sh
}

check_chezmoi_templates() {
  have chezmoi || {
    echo "chezmoi is not installed; skipping template checks."
    return 0
  }

  echo "Checking chezmoi templates..."
  chezmoi --source="$root/chezmoi" execute-template < "$root/chezmoi/.chezmoi.toml.tmpl" >/dev/null
}

check_chezmoi_diff() {
  have chezmoi || return 0

  echo "Previewing chezmoi diff..."
  chezmoi --source="$root/chezmoi" diff --exclude=scripts >/dev/null
}

check_ignored_runtime_state() {
  echo "Checking homelab ignore rules..."
  git -C "$root" check-ignore -q homelab/.env
  git -C "$root" check-ignore -q homelab/apps/pi-hole/etc-pihole/pihole.toml
}

main() {
  check_shell
  check_chezmoi_templates
  check_chezmoi_diff
  check_ignored_runtime_state
  echo "Checks passed."
}

main "$@"
