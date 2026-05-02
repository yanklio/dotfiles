# Containers

Container apps live here, but they are not all started the same way.

- `pi-hole/` runs rootful because DNS/DHCP need privileged host networking (`53/udp`, `53/tcp`, `67/udp`).
- Other apps run rootless with regular `podman compose`.

Start everything:

```bash
./scripts/start-all.sh
```

Start only Pi-hole:

```bash
./scripts/start-pihole-rootful.sh
```

Pi-hole requires `containers/.env` with `PIHOLE_PASSWORD` set.
