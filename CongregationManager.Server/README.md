# Congregation Manager sync server

A small ASP.NET Core service that relays **end-to-end encrypted** sync between
Congregation Manager devices. The Flutter app encrypts every record before
upload; this server stores ciphertext, version numbers and an ordered change
feed, and never has a key that could decrypt them.

## What the server can and cannot see

| Never visible to the server | Visible to the server (metadata) |
| --- | --- |
| Names, addresses, phone numbers, e-mail addresses | Number of records and their sizes |
| Birth and baptism dates, hope, roles, pioneer status | When records change, and which device changed them |
| Service reports and notes | Which records are deletion tombstones |
| What kind of record anything is | Number of devices, their IP addresses and last-seen times |
| Device names | |
| The vault key and the recovery code | |

Device tokens and invite codes are stored only as SHA-256 hashes. If the
server, its database or a backup is stolen, the attacker gets ciphertext and
the metadata above.

End-to-end encryption does **not** protect:

- a device that is unlocked and compromised, or the local database on a
  device (use full-disk encryption: BitLocker on Windows, the default device
  encryption on Android and iOS);
- availability: a malicious or broken server can withhold or roll back data,
  but not read or silently alter it.

## How the keys work

- **Vault key**: 256 bits of random data, created on the device that creates
  the vault. Records are sealed with XChaCha20-Poly1305. The associated data
  binds each ciphertext to its vault, record id and key id, so records
  cannot be swapped or replayed under another id.
- **Recovery code**: 256 bits of random data, shown once as 55 Crockford
  base32 characters with a checksum. HKDF-SHA256 derives two keys from it:
  - the *wrap key* encrypts the vault key; that envelope is stored on the
    server;
  - the *auth key* proves knowledge of the code. The server stores only its
    SHA-256 and sees the key itself only when it is used (recovery, key
    rotation, vault deletion).
- **Invites** carry the server address, a single-use enrollment code and the
  vault key. They expire (30 minutes to 7 days). The key inside never passes
  through the server, so invites are handed over directly: as a QR code, or
  through a private channel.
- **Key rotation** (after a device is lost): the device creates a new key and
  re-wraps it with the recovery code, optionally a new recovery code. The
  server then rejects uploads encrypted with the old key and cancels unused
  invites, and the device re-encrypts every record. Other devices enter the
  recovery code once to receive the new key.

## API (`/api/v1`)

| Method and path | Auth | Purpose |
| --- | --- | --- |
| `GET /health` | none | Liveness probe (allowed over plain HTTP) |
| `POST /vaults` | `X-Registration-Secret` | Create a vault and its first device |
| `POST /devices/enroll` | invite code | Enroll a device with an invite |
| `POST /recovery/enroll` | recovery auth key | Enroll a device with the recovery code |
| `GET /vault` | device token | Current key id, feed position, recovery envelope |
| `POST /vault/delete` | token + recovery key | Erase the vault |
| `GET /devices` | device token | List devices (names are ciphertext) |
| `DELETE /devices/{id}` | device token | Revoke a device |
| `PUT /devices/{id}/label` | device token | Set an encrypted device name |
| `POST /invites` | device token | Create a single-use invite code |
| `POST /sync/push` | device token | Upload changes (optimistic versioning, idempotent) |
| `GET /sync/pull?since=&limit=` | device token | Changes after a feed position |
| `POST /keys/rotate` | token + recovery key | Switch to a new vault key |
| `GET /keys/stale` | device token | Records still encrypted with an older key |
| `POST /keys/rekey` | device token | Replace ciphertext after rotation |

Device tokens are sent as `Authorization: Bearer <token>`. A missing, unknown
or revoked token is always rejected (fail closed). Errors are JSON:
`{ "code": "...", "message": "..." }`.

## Running locally

On Windows, with the .NET 10 SDK installed, double-click
`scripts\Start-SyncServer.cmd`, or run this from the repository root:

```powershell
.\scripts\Start-SyncServer.ps1
```

The launcher creates a cryptographically random registration secret in .NET
user secrets if the setting is missing or contains the literal placeholder
`$(openssl rand -base64 33)`. Other existing settings are preserved. It
starts the server with the Development launch profile. It works from any
working directory and does not require OpenSSL. Press Ctrl+C to stop.
To view the secret for vault creation or the end-to-end test, run
`dotnet user-secrets list --project CongregationManager.Server` from the
repository root.

Alternatively, from Bash with OpenSSL installed, run these commands from
the repository root (the first command replaces any existing secret).
Do not run these in Windows CMD: it saves `$(openssl rand -base64 33)`
literally instead of generating a secret. Use the Windows launcher above.

```sh
dotnet user-secrets set "SyncServer:Registration:Secret" "$(openssl rand -base64 33)" --project CongregationManager.Server
dotnet run --project CongregationManager.Server
```

The Development settings listen on `http://127.0.0.1:5080` and allow plain
HTTP. The app accepts `http://` only for `localhost`, `127.0.0.1` and the
Android emulator's `10.0.2.2`.

Tests: `dotnet test CongregationManager.slnx`. To run the app's end-to-end
test against a running server:

```sh
SYNC_TEST_SERVER_URL=http://127.0.0.1:5080 SYNC_TEST_REGISTRATION_SECRET=<secret> \
  flutter test test/services/sync/real_server_test.dart
```

## Deploying on a Linux VPS

1. **Runtime.** Install the ASP.NET Core 10 runtime
   (<https://learn.microsoft.com/dotnet/core/install/linux>), or publish
   self-contained with `--self-contained true`.
2. **Publish** (or download the `congregation-manager-dotnet-api-linux-x64`
   release artifact):

   ```sh
   dotnet publish CongregationManager.Server -c Release -r linux-x64 --self-contained false -o publish
   ```

3. **User and directories:**

   ```sh
   sudo useradd --system --home-dir /nonexistent --shell /usr/sbin/nologin congregation-sync
   sudo install -d -m 755 /opt/congregation-sync
   sudo install -d -o congregation-sync -g congregation-sync -m 700 /var/lib/congregation-sync
   sudo install -d -m 700 /etc/congregation-sync
   sudo cp -r publish/* /opt/congregation-sync/
   ```

4. **Configuration.** Copy `deploy/congregation-sync.env.example` to
   `/etc/congregation-sync/congregation-sync.env` (owner root, mode 600) and
   set a registration secret: `openssl rand -base64 33`.
5. **Service:**

   ```sh
   sudo cp deploy/congregation-sync.service /etc/systemd/system/
   sudo systemctl daemon-reload
   sudo systemctl enable --now congregation-sync
   journalctl -u congregation-sync -f
   ```

6. **TLS reverse proxy.** Use `deploy/Caddyfile.example` (Caddy fetches
   certificates itself) or `deploy/nginx.conf.example` with certbot. Only the
   proxy is reachable from outside; the server listens on 127.0.0.1.
7. **Check:** `curl https://sync.example.org/health` returns
   `{"status":"ok"}`, and `curl -i https://sync.example.org/api/v1/vault`
   returns `401`.
8. **Create the vault** in the app: Settings > Online Sync > Create a new
   vault. Save the recovery code (print it or put it in a password manager).
9. **Disable vault creation:** blank `SyncServer__Registration__Secret` and
   `sudo systemctl restart congregation-sync`. Existing devices keep working
   and invites still add devices.
10. **Monitoring.** Follow [Uptime Kuma setup](deploy/uptime-kuma.md) to run
    Kuma with Docker and your existing reverse proxy, monitor `/health`, and
    configure notifications.

## VPS hardening checklist

- Firewall allows only SSH, 80 and 443:
  `ufw default deny incoming && ufw allow OpenSSH && ufw allow 80,443/tcp && ufw enable`.
- SSH with keys only (`PasswordAuthentication no`, `PermitRootLogin no`);
  consider fail2ban.
- Automatic security updates (`unattended-upgrades`). Update the .NET
  runtime when patches ship, and redeploy this server when it changes.
- Port 5080 is never exposed; the app binds to loopback.
- PostgreSQL, if used: local socket or localhost only, with a dedicated role
  limited to its own database.
- Backups with `deploy/backup.sh` (age-encrypted, copied off the server).
  Test a restore once.
- An uptime monitor on `/health`: see [Uptime Kuma setup](deploy/uptime-kuma.md).
- Registration secret blank except while creating a vault.

## Runbook

| Situation | What to do in the app |
| --- | --- |
| A device is lost or stolen | Online Sync > Devices: remove it. Then More > Change encryption key. |
| The recovery code may have been seen | More > Change encryption key, with "Also create a new recovery code". |
| All devices are lost | Install the app, then "Use the recovery code" on the welcome screen. |
| A device says the key changed | Enter the recovery code when asked. |
| Erase everything on the server | More > Delete vault from server (needs the recovery code). |

## Configuration reference

All settings live under `SyncServer` and can be set as environment variables
with `__` separators (for example `SyncServer__Database__Provider`). Invalid
values stop the server at startup.

| Setting | Default | Notes |
| --- | --- | --- |
| `Database:Provider` | `Sqlite` | `Sqlite` or `Postgres` |
| `Database:ConnectionString` | `Data Source=congregation-sync.db` | Use an absolute path in production |
| `Registration:Secret` | empty | At least 24 characters; empty disables vault creation |
| `Security:RequireHttps` | `true` | Plain HTTP is refused except `/health` |
| `Security:TrustedProxies` | empty | Loopback proxies are always trusted |
| `Limits:MaxRecordBytes` | 262144 | Per encrypted record |
| `Limits:MaxOperationsPerPush` | 500 | |
| `Limits:MaxPullPageSize` | 1000 | |
| `Limits:MaxDevicesPerVault` | 25 | |
| `Limits:MaxActiveInvitesPerVault` | 10 | |
| `Limits:MaxRequestBodyBytes` | 16777216 | |
| `RateLimits:AnonymousPerMinute` | 10 | Per IP: vault creation and enrollment |
| `RateLimits:DevicePerMinute` | 600 | Per device token |

The server is meant to run as a **single instance**: writes to each vault
are serialized in-process so the change feed stays gap-free. The schema
version is stored in `cm_schema_info`, and the server refuses to start
against a newer schema than it knows.
