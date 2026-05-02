# Homelab

Local homelab services live here. Keep this separate from chezmoi-managed dotfiles.

## Layout

- `apps/`: Podman Compose app definitions.
- `services/`: host service config managed from this repo.
- `scripts/`: lifecycle scripts for this homelab stack.

## Runtime Model

- `apps/pi-hole/` runs rootful because DNS/DHCP need privileged host networking (`53/udp`, `53/tcp`, `67/udp`).
- Other apps run rootless with regular `podman compose`.

Start everything:

```bash
./scripts/start-all.sh
```

Start only Pi-hole:

```bash
./scripts/start-pihole-rootful.sh
```

Pi-hole requires `homelab/.env` with `PIHOLE_PASSWORD` set.
