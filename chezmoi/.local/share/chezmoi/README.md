# Dotfiles

Managed with [chezmoi](https://www.chezmoi.io/).

## Quick Start

```bash
# Initialize chezmoi with this repo and apply immediately
chezmoi init --apply yanklio
```

## Personal Data

Set Git identity and optional secrets in `~/.config/chezmoi/chezmoi.toml`:

```toml
[data.git]
  name = "Your Name"
  email = "you@example.com"

[data]
  wakatimeApiKey = "your-api-key-here"
```

`dot_gitconfig.tmpl` reads `data.git.*`.

`dot_config/zed/settings.json.tmpl` reads `data.wakatimeApiKey`.

## Package Setup

Packages are managed separately from dotfiles in `scripts/packages/`.

Zsh uses `oh-my-zsh` with the `simple` theme, installed by `scripts/bootstrap.sh`.

Run the bootstrap manually:

```bash
./scripts/bootstrap.sh
```

On a fresh Fedora machine, `chezmoi init --apply ...` will automatically run `scripts/bootstrap.sh` through `run_once_00_bootstrap.sh.tmpl`.

Because this is a `run_once` script, it runs once per machine unless you manually remove the generated state in chezmoi.

`run_once_00_bootstrap.sh.tmpl` only delegates to `scripts/bootstrap.sh` on Linux. The bootstrap script detects available tools directly, so there are no machine profile flags to maintain.

Package lists live in:

- `scripts/packages/common.txt`
- `scripts/packages/dnf.txt`
- `scripts/packages/go.txt`
- `scripts/packages/npm.txt`
- `scripts/packages/flatpak.txt`
- `scripts/packages/upstream.txt`

Repository-only files such as `README.md`, `AGENTS.md`, `docs/`, and `scripts/` are excluded from chezmoi apply by `.chezmoiignore`.

## Npm Packages

CLI tools that are distributed via npm are installed separately into `~/.local`.

Current npm-installed tools:

- `@anthropic-ai/claude-code`
- `opencode-ai`

Run manually:

```bash
./scripts/bootstrap.sh
```

## Daily Use

```bash
# Preview what will change
chezmoi diff

# Apply changes
chezmoi apply

# Edit a managed file
chezmoi edit ~/.config/zsh/.zshrc

# Re-import a file you changed locally
chezmoi re-add ~/.config/zsh/.zshrc
```

## Optional: GNOME Settings

GNOME desktop tweaks are applied by `scripts/bootstrap.sh` when GNOME is detected:
```bash
./scripts/bootstrap.sh
```
