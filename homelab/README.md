# Homelab

Local homelab services live here. Keep this separate from chezmoi-managed dotfiles.

## Layout

- `apps/`: Podman Compose app definitions.
- `services/`: host service config managed from this repo.
- `scripts/`: install, dispatcher, lifecycle wrappers, and shared libraries.

## Runtime Model

- `apps/pi-hole/` runs rootful because DNS/DHCP need privileged host networking (`53/udp`, `53/tcp`, `67/udp`).
- Other apps run rootless with regular `podman compose`.
- `HOMELAB_ACCESS_MODE=lan` is the default and keeps the existing LAN-oriented behavior.
- `HOMELAB_ACCESS_MODE=tailscale-only` exposes apps only through the server's Tailscale address.

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

## Tailscale-Only Access

Use this mode when the homelab should not depend on router port forwarding, LAN nginx exposure, or Pi-hole DHCP.

Set these values in `homelab/.env`:

```bash
HOMELAB_ACCESS_MODE=tailscale-only
DHCP_ACTIVE=false
HOMELAB_APPS=glance
```

In this mode, `homelab.sh start` requires the `tailscale` command, verifies `tailscale status`, detects the server IPv4 with `tailscale ip -4`, and fails clearly if no Tailscale IP is available.

Pi-hole is skipped by the normal start path, and rootless app containers bind to localhost only. The nginx command renders reverse-proxy configs so nginx listens on `<tailscale-ip>:80` instead of all LAN interfaces.

Every client device that should reach the homelab must be joined to the same tailnet. Access examples:

```text
http://<tailscale-ip>/
http://<machine-name>/
```

The machine-name form requires Tailscale MagicDNS.

### Tailnet DNS Records

Tailscale MagicDNS resolves machine names such as `gmk-de`, but it does not create app subdomains such as `glance.gmk-de`. To serve those names through the tailnet, explicitly enable Pi-hole for DNS only:

```bash
HOMELAB_ENABLE_PIHOLE_DNS=true
HOMELAB_TAILNET_DNS_SUFFIX=gmk-de
HOMELAB_TAILNET_DNS_NAMES=glance
```

With `HOMELAB_ACCESS_MODE=tailscale-only`, this keeps `DHCP_ACTIVE=false`, starts Pi-hole only when `HOMELAB_ENABLE_PIHOLE_DNS=true`, and writes Local DNS records against the detected Tailscale IPv4. For example, on this host it generates:

```text
100.127.87.82 glance.gmk-de
```

Then configure the tailnet to use this DNS server:

1. Open the Tailscale admin console.
2. Go to `DNS`.
3. Add `100.127.87.82` under `Nameservers`.
4. Enable `Override local DNS` if tailnet clients should use it automatically.
5. Keep MagicDNS enabled.

After that, clients on the tailnet can use:

```text
http://glance.gmk-de/
```

Run a dry-run preview without starting/stopping containers:

```bash
HOMELAB_DRY_RUN=1 ./scripts/homelab.sh start
```
