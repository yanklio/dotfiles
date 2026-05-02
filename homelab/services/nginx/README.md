# Nginx reverse proxy config

This directory keeps host nginx config in the repo, separate from app compose definitions.

## Apply on host

Nginx is installed from the shared package inventory and this config is linked by its own bootstrap section:

```bash
~/Dotfiles/chezmoi/.local/share/chezmoi/scripts/bootstrap.sh nginx
```

The bootstrap step creates `/etc/nginx/conf.d/home-lab.conf` as a symlink to this repo file, tests nginx, enables nginx, and reloads it.

## Route layout

- `http://glance.localhost/` -> `127.0.0.1:8080`
- `http://pihole.localhost/` -> `/admin/` -> `127.0.0.1:8081`

Add more `server` blocks for other containers bound on localhost high ports.

## Name resolution

`*.localhost` names work locally without extra DNS records. If LAN access is needed later, add a separate DNS-backed hostname setup intentionally instead of mixing it into the local config.
