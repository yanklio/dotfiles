# Homelab

Local homelab services live here. Keep this separate from chezmoi-managed dotfiles.

## Layout

- `apps/`: Podman Compose app definitions.
- `services/`: host service config managed from this repo.
- `scripts/`: install and lifecycle scripts for this homelab stack.

## Runtime Model

- `apps/pi-hole/` runs rootful because DNS/DHCP need privileged host networking (`53/udp`, `53/tcp`, `67/udp`).
- Other apps run rootless with regular `podman compose`.

Fresh server install after cloning this repo:

```bash
~/Dotfiles/homelab/scripts/install-server.sh
```

Start everything:

```bash
./scripts/start-all.sh
```

Stop, restart, or inspect containers:

```bash
./scripts/stop-all.sh
./scripts/restart-all.sh
./scripts/status.sh
```

Start only Pi-hole:

```bash
./scripts/start-pihole-rootful.sh
```

Pi-hole requires `homelab/.env` with `PIHOLE_PASSWORD` set. Set `HOMELAB_IP`, `HOMELAB_DOMAIN`, and `HOMELAB_DNS_NAMES` there to make Local DNS records transferable between machines.

Set `HOMELAB_APPS` to control rootless app startup order. It defaults to `glance`.
