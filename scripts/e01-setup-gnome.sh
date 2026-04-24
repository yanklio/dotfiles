#!/bin/bash
set -euo pipefail

if [[ "${IS_GNOME:-true}" != "true" ]]; then
    echo "Skipping GNOME settings for non-GNOME profile."
    exit 0
fi

if ! command -v gsettings >/dev/null 2>&1; then
    echo "gsettings not found."
    exit 0
fi

echo "Applying GNOME settings..."

# Alt+F4 is cumbersome on this keyboard layout.
gsettings set org.gnome.desktop.wm.keybindings close "['<Super>w']"

# Match maximize with the default left/right tiling shortcuts.
gsettings set org.gnome.desktop.wm.keybindings maximize "['<Super>Up']"

# Make undecorated windows easier to resize.
gsettings set org.gnome.desktop.wm.keybindings begin-resize "['<Super>BackSpace']"

# Full-screen with title/navigation bar.
gsettings set org.gnome.desktop.wm.keybindings toggle-fullscreen "['<Shift>F11']"

# Use 6 fixed workspaces instead of dynamic mode.
gsettings set org.gnome.mutter dynamic-workspaces false
gsettings set org.gnome.desktop.wm.preferences num-workspaces 6

# Use Alt for pinned apps.
gsettings set org.gnome.shell.keybindings switch-to-application-1 "['<Alt>1']"
gsettings set org.gnome.shell.keybindings switch-to-application-2 "['<Alt>2']"
gsettings set org.gnome.shell.keybindings switch-to-application-3 "['<Alt>3']"
gsettings set org.gnome.shell.keybindings switch-to-application-4 "['<Alt>4']"
gsettings set org.gnome.shell.keybindings switch-to-application-5 "['<Alt>5']"
gsettings set org.gnome.shell.keybindings switch-to-application-6 "['<Alt>6']"
gsettings set org.gnome.shell.keybindings switch-to-application-7 "['<Alt>7']"
gsettings set org.gnome.shell.keybindings switch-to-application-8 "['<Alt>8']"
gsettings set org.gnome.shell.keybindings switch-to-application-9 "['<Alt>9']"

# Use Super for workspaces.
gsettings set org.gnome.desktop.wm.keybindings switch-to-workspace-1 "['<Super>1']"
gsettings set org.gnome.desktop.wm.keybindings switch-to-workspace-2 "['<Super>2']"
gsettings set org.gnome.desktop.wm.keybindings switch-to-workspace-3 "['<Super>3']"
gsettings set org.gnome.desktop.wm.keybindings switch-to-workspace-4 "['<Super>4']"
gsettings set org.gnome.desktop.wm.keybindings switch-to-workspace-5 "['<Super>5']"
gsettings set org.gnome.desktop.wm.keybindings switch-to-workspace-6 "['<Super>6']"

echo "GNOME settings applied."
