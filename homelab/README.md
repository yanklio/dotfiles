# Homelab

Local homelab services live here. Keep this separate from chezmoi-managed dotfiles.

## Layout

- `apps/`: Podman Compose app definitions.
- `services/`: host service config managed from this repo.
- `scripts/`: install, dispatcher, lifecycle wrappers, and shared libraries.

## Runtime Model

- `apps/pi-hole/` runs rootful because DNS/DHCP need privileged host networking (`53/udp`, `53/tcp`, `67/udp`).
- Other apps run rootless with regular `podman compose`.

Fresh server install after cloning this repo:

```bash
~/Dotfiles/homelab/scripts/install-server.sh
```

Manage the stack with the main dispatcher:

```bash
~/Dotfiles/homelab/scripts/homelab.sh start
~/Dotfiles/homelab/scripts/homelab.sh stop
~/Dotfiles/homelab/scripts/homelab.sh restart
~/Dotfiles/homelab/scripts/homelab.sh status
~/Dotfiles/homelab/scripts/homelab.sh doctor
```

The older lifecycle commands are wrappers around the dispatcher:

```bash
./scripts/start-all.sh
./scripts/stop-all.sh
./scripts/restart-all.sh
./scripts/status.sh
```

Start only Pi-hole:

```bash
./scripts/start-pihole-rootful.sh
```

Pi-hole requires `homelab/.env` with `PIHOLE_PASSWORD` set. Keep that file private; scripts tighten it to mode `600` when they read or generate it.

Set `HOMELAB_IP`, `HOMELAB_DOMAIN`, and `HOMELAB_DNS_NAMES` there to make Local DNS records transferable between machines.

Set `HOMELAB_APPS` to control rootless app startup order. It defaults to `glance`.

Run a dry-run preview without starting/stopping containers:

```bash
HOMELAB_DRY_RUN=1 ./scripts/homelab.sh start
```
