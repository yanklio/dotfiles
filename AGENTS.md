# Agent Notes

## Repository Shape
- This repository root is `~/Dotfiles`.
- `chezmoi/` is a GNU Stow package. It maps `chezmoi/.local/share/chezmoi` to `~/.local/share/chezmoi`.
- The live chezmoi source path should remain a symlink managed by stow: `~/.local/share/chezmoi -> ~/Dotfiles/chezmoi/.local/share/chezmoi`.
- `scripts/stow-chezmoi.sh` copies an existing chezmoi source into the stow package and stows it back into place.
- Do not move the git repository back inside `chezmoi/.local/share/chezmoi`; git should stay at `~/Dotfiles/.git`.

## Chezmoi Source
- The actual chezmoi source tree is `chezmoi/.local/share/chezmoi`.
- Files in that tree use chezmoi naming rules: `dot_` renders to `.`, `run_once_` runs once, and `.tmpl` files are rendered by chezmoi.
- Keep local agent tooling out of managed dotfiles. `.opencode/` inside the chezmoi source is ignored intentionally.
- Package inventories live in `chezmoi/.local/share/chezmoi/scripts/packages/`.

## Bootstrap Flow
- `chezmoi/.local/share/chezmoi/run_once_00_bootstrap.sh.tmpl` is the chezmoi auto-run entrypoint.
- It renders machine flags and calls `chezmoi/.local/share/chezmoi/scripts/bootstrap.sh`.
- Prefer one readable bootstrap script over many numbered helper scripts unless there is a clear maintenance reason to split it again.

## Verification
- Check stow wiring with: `stow --dir="$HOME/Dotfiles" --target="$HOME" --simulate --verbose chezmoi`.
- Check shell syntax with: `bash -n chezmoi/.local/share/chezmoi/scripts/bootstrap.sh`.
- Check the rendered chezmoi bootstrap template with: `bash -n <(chezmoi execute-template < chezmoi/.local/share/chezmoi/run_once_00_bootstrap.sh.tmpl)`.
- Preview chezmoi changes from the source tree with: `chezmoi diff --exclude=scripts`.
