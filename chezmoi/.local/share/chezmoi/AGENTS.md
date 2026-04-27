# Agent Notes

## Repository Shape
- This is a chezmoi source tree; `dot_` files render to dotfiles and `run_once_*.tmpl` scripts execute from chezmoi, not directly from the repo root.
- Do not import agent skills into this repo; `.opencode/` is local tooling and should stay out of managed dotfiles unless explicitly requested.
- `.chezmoiignore` keeps repo-only files such as `README.md`, `AGENTS.md`, `docs/`, `scripts/`, `.opencode/`, and `.gitignore` out of `$HOME`.
- Package inventories are in `scripts/packages/`; preserve package lists unless the user explicitly asks to change packages.

## Bootstrap Flow
- `.chezmoi.toml.tmpl` only configures chezmoi editor/merge commands.
- `run_once_00_bootstrap.sh.tmpl` is the only chezmoi auto-run entrypoint; it calls `scripts/bootstrap.sh` on Linux.
- Do not call `chezmoi source-path` from inside a `run_once` script; nested chezmoi calls can deadlock on the persistent state lock during `chezmoi apply`.
- `scripts/bootstrap.sh` is the single bootstrap script and detects available tools directly. It reads package/tool inventories from `scripts/packages/`, then runs dnf packages, Go tools, shell setup, npm globals, upstream CLI installers, Flatpaks, systemd user services, and GNOME settings.

## Verification
- Render templates: `chezmoi execute-template < .chezmoi.toml.tmpl` and `chezmoi execute-template < run_once_00_bootstrap.sh.tmpl`.
- Check shell syntax: `bash -n scripts/*.sh` and `bash -n <(chezmoi execute-template < run_once_00_bootstrap.sh.tmpl)`.
- Preview apply impact before changing live files: `chezmoi diff`.
- If `.chezmoi.toml.tmpl` changes, run `chezmoi init` so chezmoi refreshes config state before relying on `chezmoi apply`.

## Install Gotchas
- `scripts/bootstrap.sh` needs an interactive TTY for sudo; non-interactive agent runs will skip dnf installation with `No TTY available for sudo.`
- Zed and Ollama are installed by `scripts/bootstrap.sh` from `scripts/packages/upstream.txt`.
- Flatpaks are installed by `scripts/bootstrap.sh` from `scripts/packages/flatpak.txt`; the script skips apps that cannot install non-interactively.
- npm globals install into `~/.local` via `npm install --global --prefix "$HOME/.local"`.

## Config Gotchas
- `dot_config/zed/settings.json.tmpl` reads `data.wakatimeApiKey`; missing data intentionally renders an empty API key.
- GNOME automation lives in `scripts/bootstrap.sh`, runs only when GNOME is detected, and sets keybindings/workspaces, not just idle-delay.
