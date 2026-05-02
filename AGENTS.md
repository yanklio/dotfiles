# Agent Notes

## Repository Shape
- This repository root is `~/Dotfiles`.
- Chezmoi uses `~/Dotfiles/chezmoi` directly as its source directory.
- Homelab server/container config lives in `homelab` and is intentionally separate from chezmoi-managed dotfiles.
- First-run install scripts live in `scripts/`; `scripts/install.sh` is the main entrypoint, with distro-specific wrappers beside it.
- Do not move the git repository inside the chezmoi source; git should stay at `~/Dotfiles/.git`.

## Chezmoi Source
- The actual chezmoi source tree is `chezmoi`.
- Files in that tree use chezmoi naming rules: `dot_` renders to `.`, and `.tmpl` files are rendered by chezmoi.
- Keep local agent tooling out of managed dotfiles. `.opencode/` inside the chezmoi source is ignored intentionally.
- Package inventories live in `chezmoi/scripts/packages/`.

## Bootstrap Flow
- `chezmoi apply` should only manage dotfiles.
- First-run install scripts call `chezmoi/scripts/bootstrap.sh` explicitly after `chezmoi apply`.
- Keep `chezmoi/scripts/bootstrap.sh` as a small dispatcher and put implementation in focused `chezmoi/scripts/lib/*.sh` modules.

## Homelab
- The fresh-server installer is `homelab/scripts/install-server.sh`.
- Homelab lifecycle goes through `homelab/scripts/homelab.sh`; the older lifecycle scripts are wrappers.
- Keep homelab implementation in focused `homelab/scripts/lib/*.sh` modules when it would otherwise become hard to read.
- Homelab runtime state and secrets are ignored by `homelab/.gitignore`.

## Verification
- Run all repository checks with: `scripts/check.sh`.
- If diagnosing manually, check shell syntax with: `bash -n scripts/*.sh homelab/scripts/*.sh homelab/scripts/lib/*.sh chezmoi/scripts/bootstrap.sh chezmoi/scripts/lib/*.sh`.
- Preview chezmoi changes from the source tree with: `chezmoi --source="$HOME/Dotfiles/chezmoi" diff --exclude=scripts`.
