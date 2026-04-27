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

Packages are managed separately from dotfiles.

Zsh uses `oh-my-zsh` with the `simple` theme, installed by `scripts/bootstrap.sh`.

Run the bootstrap manually:

```bash
./scripts/bootstrap.sh
```

On a fresh Fedora machine, `chezmoi init --apply ...` will automatically run `scripts/bootstrap.sh` through `run_once_00_bootstrap.sh.tmpl`.

Because this is a `run_once` script, it runs once per machine unless you manually remove the generated state in chezmoi.

Machine profile flags are rendered in `.chezmoi.toml.tmpl` and exported by `run_once_00_bootstrap.sh.tmpl` before delegating to `scripts/bootstrap.sh`:

- `IS_GNOME`
- `IS_FEDORA`
- `IS_DEBIAN`
- `PKG`

`scripts/bootstrap.sh` is the single bootstrap script. Distro-specific sections short-circuit when the rendered profile does not apply.

Package lists live in:

- `scripts/packages/common.txt`
- `scripts/packages/dnf.txt`
- `scripts/packages/npm.txt`

Some packages in `scripts/packages/dnf.txt` stay commented because they need manual review, COPR, or non-`dnf` installation.

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
chezmoi apply --exclude=scripts

# Edit a managed file
chezmoi edit ~/.config/zsh/.zshrc

# Re-import a file you changed locally
chezmoi re-add ~/.config/zsh/.zshrc
```

## Optional: GNOME Settings

Apply GNOME desktop tweaks:
```bash
./scripts/bootstrap.sh
```
