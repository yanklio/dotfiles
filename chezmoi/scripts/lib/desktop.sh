apply_gnome_settings() {
  have gsettings || return 0
  is_gnome || return 0

  echo "Applying GNOME settings..."
  run_cmd gsettings set org.gnome.desktop.wm.keybindings close "['<Super>w']"
  run_cmd gsettings set org.gnome.desktop.wm.keybindings maximize "['<Super>Up']"
  run_cmd gsettings set org.gnome.desktop.wm.keybindings begin-resize "['<Super>BackSpace']"
  run_cmd gsettings set org.gnome.desktop.wm.keybindings toggle-fullscreen "['<Shift>F11']"
  run_cmd gsettings set org.gnome.mutter dynamic-workspaces false
  run_cmd gsettings set org.gnome.desktop.wm.preferences num-workspaces 6

  for i in 1 2 3 4 5 6 7 8 9; do
    run_cmd gsettings set org.gnome.shell.keybindings "switch-to-application-$i" "['<Alt>$i']"
  done

  for i in 1 2 3 4 5 6; do
    run_cmd gsettings set org.gnome.desktop.wm.keybindings "switch-to-workspace-$i" "['<Super>$i']"
  done
}
