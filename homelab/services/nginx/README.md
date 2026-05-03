# Nginx reverse proxy config

This directory keeps host nginx config in the repo, split per service.

## Files

- `00-default.conf` — default server that routes `/` to Glance
- `glance.localhost.conf` — Glance dashboard
- `pihole.localhost.conf` — Pi-hole admin UI

## Apply on host

Nginx is installed on all machines, but this homelab reverse-proxy config is server-only. Normal client bootstraps leave nginx config untouched unless the machine role is set to `server`.

Set the role on the homelab server in `~/.config/chezmoi/chezmoi.toml`:

```toml
[data]
  machineRole = "server"
```

Then run the normal bootstrap, or force only nginx setup with the homelab dispatcher:

```bash
~/Dotfiles/homelab/scripts/homelab.sh nginx
```

The bootstrap step:
1. Renders all `*.conf` from `homelab/services/nginx/conf.d/` to `/etc/nginx/conf.d/`
2. Disables default nginx sites
3. Tests nginx config
4. Enables and reloads nginx

## Route layout

- `http://<server>/` → `127.0.0.1:8080`
- `http://glance.localhost/`, `http://glance.home/`, and `http://glance.gmk-de/` → `127.0.0.1:8080`
- `http://pihole.localhost/` and `http://pihole.home/` → `/admin/` → `127.0.0.1:8081`

Add more per-service `*.localhost.conf` files for other containers bound on localhost high ports.

## Name resolution

`*.localhost` names work locally without extra DNS records. `*.home` names are for LAN clients and should be added as Pi-hole Local DNS records pointing at the homelab server IP.

## Tailscale-Only Mode

With `HOMELAB_ACCESS_MODE=tailscale-only`, nginx configs are rendered with `listen <tailscale-ip>:80;` instead of `listen 80;`. Normal app containers bind to localhost, so LAN clients cannot bypass nginx by connecting directly to app ports.

All client devices must be joined to the same tailnet. Use `http://<tailscale-ip>/`, `http://<machine-name>/`, or `http://glance.gmk-de/` when Tailnet DNS is configured to resolve that app name.
