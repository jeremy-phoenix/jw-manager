# Monitoring with Uptime Kuma

Run Uptime Kuma as a separate Docker Compose service on your Linux VPS and
monitor the sync server's public HTTPS endpoint. This guide assumes Docker
Engine, Docker Compose, and a reverse proxy are already installed.

Replace `sync.example.org` with your API hostname and `uptime.example.org`
with the hostname you want for Kuma. No changes to the sync server are needed.

## What the monitor checks

`GET https://sync.example.org/health` returns HTTP `200` and
`{"status":"ok"}` without authentication. The path is `/health`, not
`/api/v1/health`. Use it for monitoring; `/` is the human-readable home page.

This is a liveness check: it confirms that the server responds. It does not
query the database or test a complete sync operation. Using the public HTTPS
URL also exercises DNS, the reverse proxy, and certificate validation from
Kuma's location.

If Kuma shares the API's VPS, it cannot send alerts while that VPS is down or
loses network connectivity. Use an additional monitor outside the VPS to
detect those outages and check availability from outside the host.

## Start Kuma

On the VPS:

```sh
sudo mkdir -p /opt/uptime-kuma
cd /opt/uptime-kuma
sudo nano compose.yaml
```

Save the following configuration. It uses a persistent Docker volume on local
storage and exposes the dashboard only on the host's loopback address.

```yaml
services:
  uptime-kuma:
    image: louislam/uptime-kuma:2
    restart: unless-stopped
    ports:
      - "127.0.0.1:3001:3001"
    volumes:
      - kuma-data:/app/data

volumes:
  kuma-data:
```

```sh
sudo docker compose up -d
sudo docker compose ps
sudo docker compose logs --tail=50
```

For initial setup, run this from your own computer, replacing the SSH user
and VPS address:

```sh
ssh -N -L 3001:127.0.0.1:3001 YOUR_USER@YOUR_VPS_IP
```

Keep the SSH session open, visit `http://localhost:3001`, and create your
administrator account before exposing Kuma through the reverse proxy.
You can also keep using the SSH tunnel for private dashboard access.

## Connect the existing reverse proxy

For HTTPS dashboard access, point the DNS record for `uptime.example.org` at
the VPS and add a separate site to your existing proxy. Kuma needs WebSocket
support and its own hostname; hosting it under `/uptime` is not supported.
Port 3001 does not need to be opened in the public firewall.

### Proxy running directly on the VPS

Keep the Compose configuration above. The upstream is `127.0.0.1:3001`.

For Caddy, add this block to the existing `/etc/caddy/Caddyfile`:

```caddyfile
uptime.example.org {
    reverse_proxy 127.0.0.1:3001
}
```

Validate and reload Caddy:

```sh
sudo caddy validate --config /etc/caddy/Caddyfile
sudo systemctl reload caddy
```

For Nginx, create a separate HTTPS virtual host for `uptime.example.org` using
your existing certificate-management process. Use this location block inside
that virtual host:

```nginx
location / {
    proxy_pass http://127.0.0.1:3001;
    proxy_http_version 1.1;
    proxy_set_header Host $host;
    proxy_set_header X-Real-IP $remote_addr;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Proto $scheme;
    proxy_set_header Upgrade $http_upgrade;
    proxy_set_header Connection "upgrade";
}
```

After configuring the virtual host and its certificate:

```sh
sudo nginx -t
sudo systemctl reload nginx
```

### Proxy running inside Docker

The proxy and Kuma must share a Docker network. Find the proxy's existing
network with `sudo docker network ls` and `sudo docker inspect YOUR_PROXY_CONTAINER`.
Replace `YOUR_EXISTING_PROXY_NETWORK` below with that network's actual name.
After initial account setup, replace `compose.yaml` with:

```yaml
services:
  uptime-kuma:
    image: louislam/uptime-kuma:2
    restart: unless-stopped
    volumes:
      - kuma-data:/app/data
    networks:
      - proxy

volumes:
  kuma-data:

networks:
  proxy:
    external: true
    name: YOUR_EXISTING_PROXY_NETWORK
```

Run `sudo docker compose up -d` again from `/opt/uptime-kuma`. Keeping the same
directory and volume declaration preserves your account and settings.
This configuration removes the host port, so the SSH tunnel above is no longer
available. Configure the proxy to reach `http://uptime-kuma:3001` on the shared
network; `127.0.0.1` inside the proxy container refers to the proxy itself.

- **Caddy or Nginx:** use the examples above, replacing the upstream
  `127.0.0.1:3001` with `uptime-kuma:3001`. Validate and reload using your
  existing container deployment process.
- **Nginx Proxy Manager:** create a Proxy Host for `uptime.example.org` with
  scheme `http`, forward hostname `uptime-kuma`, and forward port `3001`.
  Enable Websockets Support and configure an SSL certificate and Force SSL.
- **Traefik:** add a router for ``Host(`uptime.example.org`)`` using your existing
  HTTPS entrypoint and certificate resolver, and set its service's
  `loadbalancer.server.port` to `3001`. Use the actual shared network name for
  `traefik.docker.network` if needed. See the official reverse-proxy examples
  linked below for the label syntax.

Visit `https://uptime.example.org` and sign in with the account you created.

## Add the sync server monitor

Choose **Add New Monitor** and configure:

| Setting | Value |
| --- | --- |
| Monitor type | HTTP(s) - JSON Query |
| Friendly name | Congregation Manager API |
| URL | `https://sync.example.org/health` |
| Method | GET |
| Accepted status codes | `200` |
| JSON query expression | `status` |
| Condition | `==` |
| Expected value | `ok` |
| Heartbeat interval | 60 seconds |
| Retries | 2 |
| Request timeout | 10 seconds |
| Authentication | None |

Keep TLS certificate validation enabled. Do not add a device token or the
registration secret. Use the public URL even when Kuma shares the API's host;
`localhost` inside the Kuma container refers to Kuma, not the API.

Save the monitor and confirm that it turns green. Configure your preferred
notification provider, send a test notification, and assign it to this monitor.
Confirm that the test message arrives; saving a provider alone does not enable
notifications for every monitor.

## Maintenance

Back up the `kuma-data` volume to storage outside the VPS. Stop Kuma while
taking a filesystem copy of its data so the SQLite database backup is
consistent, then start it again. Keep the Compose file with your backup.
Use local storage for the live data volume, not an NFS share.

After backing up and reviewing the release notes, update within v2 with:

```sh
cd /opt/uptime-kuma
sudo docker compose pull
sudo docker compose up -d
sudo docker compose logs --tail=50
```

Confirm the monitor is green after the update. Do not use
`docker compose down -v` unless you intend to delete Kuma's stored data.

## Official references

- [Uptime Kuma installation](https://github.com/louislam/uptime-kuma/wiki/%F0%9F%94%A7-How-to-Install)
- [Reverse-proxy examples, including Traefik](https://github.com/louislam/uptime-kuma/wiki/Reverse-Proxy)
- [Notification providers](https://github.com/louislam/uptime-kuma/wiki/Notification-Methods)
- [Releases](https://github.com/louislam/uptime-kuma/releases)
