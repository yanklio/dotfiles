# Agent Notes

## Repository Shape
- This is a chezmoi source tree; `dot_` files render to dotfiles and `.tmpl` files render through chezmoi.
- Do not import agent skills into this repo; `.opencode/` is local tooling and should stay out of managed dotfiles unless explicitly requested.
- `.chezmoiignore` keeps repo-only files such as `README.md`, `AGENTS.md`, `docs/`, `scripts/`, `.opencode/`, and `.gitignore` out of `$HOME`.
- `.chezmoidata.toml` stores non-secret template defaults; machine-local overrides belong in `~/.config/chezmoi/chezmoi.toml`.
- `machineRole` controls server-only bootstrap behavior; `gnomeSettings` supports `auto`, `on`, or `off`.
- Package inventories are in `scripts/packages/`; preserve package lists unless the user explicitly asks to change packages.

## Bootstrap Flow
- `.chezmoi.toml.tmpl` only configures chezmoi editor/merge commands.
- `chezmoi apply` should only manage dotfiles; it should not auto-install packages or tools.
- `scripts/bootstrap.sh` is called explicitly by first-run install scripts or manually by the user.
- `scripts/bootstrap.sh` is the bootstrap dispatcher. Keep implementation in focused `scripts/lib/*.sh` modules when it would otherwise become hard to read.

## Verification
- Render templates: `chezmoi execute-template < .chezmoi.toml.tmpl`.
- Check shell syntax: `bash -n scripts/*.sh scripts/lib/*.sh`.
- Preview apply impact before changing live files: `chezmoi diff`.
- If `.chezmoi.toml.tmpl` changes, run `chezmoi init` so chezmoi refreshes config state before relying on `chezmoi apply`.

## Install Gotchas
- `scripts/bootstrap.sh` needs an interactive TTY for sudo; non-interactive agent runs will skip dnf installation with `No TTY available for sudo.`
- Zed and Ollama are installed by `scripts/bootstrap.sh` from `scripts/packages/upstream.txt`.
- Flatpaks are installed by `scripts/bootstrap.sh` from `scripts/packages/flatpak.txt`; the script skips apps that cannot install non-interactively.
- npm globals install into `~/.local` via `npm install --global --prefix "$HOME/.local"`.

## Config Gotchas
- `dot_config/zed/private_settings.json.tmpl` reads `data.wakatimeApiKey`; missing data intentionally renders an empty API key.
- GNOME automation lives in `scripts/bootstrap.sh`, runs when GNOME is detected unless `gnomeSettings` forces it on or off, and sets keybindings/workspaces, not just idle-delay.
