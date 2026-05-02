# Nginx reverse proxy config

This directory keeps host nginx config in the repo, split per service.

## Files

- `00-default.conf` — default server (404)
- `glance.localhost.conf` — Glance dashboard
- `pihole.localhost.conf` — Pi-hole admin UI

## Apply on host

Nginx is installed on all machines, but this homelab reverse-proxy config is server-only. Normal client bootstraps leave nginx config untouched unless the machine role is set to `server`.

Set the role on the homelab server in `~/.config/chezmoi/chezmoi.toml`:

```toml
[data]
  machineRole = "server"
```

Then run the normal bootstrap, or force only nginx setup with:

```bash
~/Dotfiles/chezmoi/.local/share/chezmoi/scripts/bootstrap.sh nginx
```

The bootstrap step:
1. Symlinks all `*.conf` from `homelab/services/nginx/conf.d/` → `/etc/nginx/conf.d/`
2. Disables default nginx sites
3. Tests nginx config
4. Enables and reloads nginx

## Route layout

- `http://glance.localhost/` → `127.0.0.1:8080`
- `http://pihole.localhost/` → `/admin/` → `127.0.0.1:8081`

Add more per-service `*.localhost.conf` files for other containers bound on localhost high ports.

## Name resolution

`*.localhost` names work locally without extra DNS records. If LAN access is needed later, add a separate DNS-backed hostname setup intentionally instead of mixing it into the local config.
