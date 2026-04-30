---
name: chezmoi-dotfiles
description: >
  Maintain this stow-packaged chezmoi dotfiles source. Use this skill whenever the
  user mentions dotfiles, chezmoi, GNU Stow wiring, bootstrapping a Linux machine,
  package inventories, zsh config, Neovim config, terminal config, Git identity,
  GNOME settings, Flatpaks, npm globals, Go tools, upstream CLI installers, or
  extending scripts/bootstrap.sh in this repository.
---

# chezmoi Dotfiles Skill

Use this skill to work on the current dotfiles repository, not a generic chezmoi
scaffold. The repo is intentionally small: chezmoi manages config files, while a
single bootstrap script handles packages, tools, services, and GNOME tweaks.

## Repository shape

The git repository root is `~/Dotfiles`.

The chezmoi source is stored inside a GNU Stow package:

```text
~/Dotfiles/
└── chezmoi/
    └── .local/share/chezmoi/   # actual chezmoi source tree
```

The live chezmoi source path should be stow-managed:

```text
~/.local/share/chezmoi -> ~/Dotfiles/chezmoi/.local/share/chezmoi
```

Do not move the git repository into the chezmoi source. Git should stay at
`~/Dotfiles/.git`.

## Current source layout

```text
chezmoi/.local/share/chezmoi/
├── .chezmoi.toml.tmpl           # editor and merge tool config only
├── .chezmoidata.toml            # non-secret template defaults
├── .chezmoiignore               # excludes repo-only files from apply
├── .gitignore
├── AGENTS.md                    # local agent guidance, ignored by chezmoi
├── README.md                    # repo docs, ignored by chezmoi
├── docs/
│   └── nvim-keys.md
├── dot_gitconfig.tmpl           # renders from data.git.*
├── dot_config/
│   ├── alacritty/alacritty.toml
│   ├── fastfetch/config.jsonc
│   ├── ghostty/config
│   ├── nvim/
│   │   ├── init.lua
│   │   └── lua/config/*.lua
│   ├── tmux/tmux.conf
│   ├── vim/dot_vimrc
│   ├── zed/settings.json.tmpl   # reads data.wakatimeApiKey
│   └── zsh/dot_zshrc
├── run_once_00_bootstrap.sh.tmpl # only chezmoi auto-run entrypoint
└── scripts/
    ├── bootstrap.sh             # single bootstrap implementation
    └── packages/
        ├── common.txt
        ├── dnf.txt
        ├── flatpak.txt
        ├── go.txt
        ├── npm.txt
        └── upstream.txt
```

`.opencode/` also exists in the source tree for local agent tooling. It is
explicitly ignored by `.chezmoiignore` and should not be treated as a managed
dotfile directory unless the user explicitly asks to edit it.

## Core chezmoi concepts

| Prefix or suffix | Effect at `chezmoi apply` |
|---|---|
| `dot_` | Renders to a leading `.` in the destination |
| `private_` | Sets mode `0600` |
| `executable_` | Sets executable mode |
| `run_once_` | Runs once per machine/content state |
| `run_onchange_` | Runs when rendered content changes |
| `.tmpl` | Renders as a Go template before use |

Useful built-in template variables:

- `.chezmoi.sourceDir`: absolute source directory path
- `.chezmoi.os`: `linux`, `darwin`, etc.
- `.chezmoi.hostname`: machine hostname
- `.chezmoi.osRelease.id`: distro id when available

## Data model

`.chezmoi.toml.tmpl` currently only configures tools:

```toml
[merge]
  command = "nvim -d"

[edit]
  command = "nvim"
```

Non-secret defaults live in `.chezmoidata.toml`:

```toml
wakatimeApiKey = ""

[git]
name = "yanklio"
email = "y.ustinov2004@gmail.com"
```

Machine-local overrides belong in `~/.config/chezmoi/chezmoi.toml`:

```toml
[data.git]
  name = "Your Name"
  email = "you@example.com"

[data]
  wakatimeApiKey = "your-api-key-here"
```

Do not add machine profile flags unless there is a concrete need. The current
bootstrap detects available tools and desktop environment directly.

## Bootstrap flow

`run_once_00_bootstrap.sh.tmpl` is the only chezmoi auto-run entrypoint. It only
runs on Linux and delegates to `scripts/bootstrap.sh`:

```bash
{{- if eq .chezmoi.os "linux" -}}
#!/usr/bin/env bash
set -euo pipefail

SCRIPTS_DIR={{ .chezmoi.sourceDir | quote }}/scripts

exec bash "$SCRIPTS_DIR/bootstrap.sh" "$@"
{{- end -}}
```

Important rule: do not call `chezmoi source-path` from inside a `run_once` script.
Nested chezmoi calls can deadlock on the persistent state lock during
`chezmoi apply`. Use `.chezmoi.sourceDir` in the template instead.

`scripts/bootstrap.sh` is the single bootstrap script. It supports these sections:

- `all`: default; run every section
- `packages`: install Fedora packages with `dnf` when available
- `go`: install Go tools from `scripts/packages/go.txt`
- `shell`: install oh-my-zsh unattended
- `npm`: install npm globals into `~/.local`
- `upstream`: run upstream CLI installers from `scripts/packages/upstream.txt`
- `flatpak`: install Flatpak apps from `scripts/packages/flatpak.txt`
- `services`: enable user/system services when tools exist
- `gnome`: apply GNOME settings when GNOME is detected

Examples:

```bash
./scripts/bootstrap.sh
./scripts/bootstrap.sh packages npm flatpak gnome
./scripts/bootstrap.sh help
```

Because the entrypoint is `run_once`, it runs once per machine/content state
unless chezmoi state is manually cleared or the rendered script changes.

## Package inventories

Package and tool lists are data files, not separate numbered scripts:

- `common.txt`: packages shared with distro-specific package installation
- `dnf.txt`: Fedora packages installed through `dnf`
- `go.txt`: `go install` module specs
- `npm.txt`: npm package names installed with `npm install --global --prefix "$HOME/.local"`
- `flatpak.txt`: Flatpak app IDs installed from Flathub
- `upstream.txt`: pipe-delimited `command|Display Name|install-url` rows

Preserve package lists unless the user explicitly asks to change packages.

## Managed configs

Current managed config areas:

- Git: `dot_gitconfig.tmpl`, rendered from `data.git.name` and `data.git.email`
- Zsh: `dot_config/zsh/dot_zshrc`, with oh-my-zsh installed by bootstrap
- Neovim: `dot_config/nvim/init.lua` and `dot_config/nvim/lua/config/*.lua`
- Vim: `dot_config/vim/dot_vimrc`
- Tmux: `dot_config/tmux/tmux.conf`
- Terminals: Alacritty and Ghostty configs
- Fastfetch: `dot_config/fastfetch/config.jsonc`
- Zed: `dot_config/zed/settings.json.tmpl`, including optional Wakatime API key

## Ignored repo-only files

`.chezmoiignore` excludes files that should not be written into `$HOME`:

```text
README.md
AGENTS.md
docs/**
scripts/**
.opencode/**
.gitignore
```

Even though `scripts/**` is ignored by chezmoi apply, it is still available in
the source tree and is called by `run_once_00_bootstrap.sh.tmpl`.

## Verification

From `~/Dotfiles`, verify Stow wiring:

```bash
stow --dir="$HOME/Dotfiles" --target="$HOME" --simulate --verbose chezmoi
```

From `chezmoi/.local/share/chezmoi`, verify chezmoi and shell changes:

```bash
chezmoi execute-template < .chezmoi.toml.tmpl
chezmoi execute-template < run_once_00_bootstrap.sh.tmpl
bash -n scripts/*.sh
bash -n <(chezmoi execute-template < run_once_00_bootstrap.sh.tmpl)
chezmoi diff --exclude=scripts
```

If `.chezmoi.toml.tmpl` changes, run `chezmoi init` so chezmoi refreshes config
state before relying on `chezmoi apply`.

## Install gotchas

- `scripts/bootstrap.sh` needs an interactive TTY for sudo; non-interactive agent
  runs will skip dnf installation with `No TTY available for sudo.`
- Zed and Ollama are installed through `scripts/packages/upstream.txt` when their
  commands are missing and `curl` exists.
- Flatpak installation is non-interactive and may skip apps that cannot install
  cleanly in user or system scope.
- GNOME settings are applied only when GNOME is detected through desktop session
  environment variables.

## Daily workflow

```bash
chezmoi diff
chezmoi apply
chezmoi edit ~/.config/zsh/.zshrc
chezmoi re-add ~/.config/zsh/.zshrc
```

For repository work, edit files in:

```text
~/Dotfiles/chezmoi/.local/share/chezmoi
```

## Extending this repo

- New managed config: add the appropriately named chezmoi source file, for
  example `dot_config/app/config.toml` for `~/.config/app/config.toml`.
- New template data: add safe defaults to `.chezmoidata.toml`; use
  `~/.config/chezmoi/chezmoi.toml` for machine-local or secret values.
- New package/tool: add it to the correct `scripts/packages/*.txt` inventory.
- New bootstrap behavior: prefer adding a small function and section to
  `scripts/bootstrap.sh` over creating many numbered scripts.
- New OS support: add direct tool/distro detection in `scripts/bootstrap.sh`; do
  not introduce profile flags unless detection is not enough.
- New secret backend: this repo does not currently configure `pass`, `age`, or
  another backend. Add one only when requested, and keep plaintext secrets out of
  the repository.
