# Dotfiles

Personal workstation and homelab configuration.

## Layout

- `chezmoi/`: the chezmoi source tree. Chezmoi is responsible for dotfiles in `$HOME`.
- `homelab/`: container apps and host service config for the homelab server.
- `scripts/`: first-run install scripts that install base dependencies, clone this repo, and hand off to chezmoi.

## First Run

Auto-detect Fedora, Debian, or Ubuntu:

```bash
curl -fsSL https://raw.githubusercontent.com/yanklio/dotfiles/main/scripts/install.sh | bash
```

Force a distro when needed:

```bash
curl -fsSL https://raw.githubusercontent.com/yanklio/dotfiles/main/scripts/fedora-install.sh | bash
curl -fsSL https://raw.githubusercontent.com/yanklio/dotfiles/main/scripts/debian-install.sh | bash
```

The install scripts install `git`, `curl`, `ca-certificates`, and `chezmoi`, clone this repo to `~/Dotfiles`, then run:

```bash
chezmoi init --source="$HOME/Dotfiles/chezmoi"
chezmoi apply
```

Override the clone target or repository when needed:

```bash
curl -fsSL https://raw.githubusercontent.com/yanklio/dotfiles/main/scripts/install.sh | bash -s -- --dir "$HOME/src/Dotfiles" --repo "https://github.com/yanklio/dotfiles.git"
```

Pass installer flags after the downloaded script:

```bash
curl -fsSL https://raw.githubusercontent.com/yanklio/dotfiles/main/scripts/install.sh | bash -s -- --server --no-gnome
```

Supported flags are `--server`, `--client`, `--gnome`, `--no-gnome`, `--repo URL`, `--dir PATH`, and `--distro NAME`.

## Dotfiles

Initialize and apply the dotfiles source directly:

```bash
chezmoi init --source="$HOME/Dotfiles/chezmoi"
chezmoi apply
```

Preview changes before applying:

```bash
chezmoi --source="$HOME/Dotfiles/chezmoi" diff --exclude=scripts
```

Dotfiles are applied with chezmoi. Packages, tools, services, and GNOME settings are handled explicitly by `chezmoi/scripts/bootstrap.sh`; the first-run installer calls it after `chezmoi apply`.

Run repository checks:

```bash
~/Dotfiles/scripts/check.sh
```

## Homelab

Homelab files are intentionally outside the chezmoi source. Install a fresh server with:

```bash
~/Dotfiles/homelab/scripts/install-server.sh
```

Runtime state and secrets under `homelab/` are ignored by git.
