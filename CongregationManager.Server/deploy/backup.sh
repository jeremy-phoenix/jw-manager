#!/usr/bin/env bash
# Nightly backup of the SQLite sync database. Install and schedule it:
#   sudo install -m 700 backup.sh /usr/local/sbin/congregation-sync-backup
#   root crontab:  15 3 * * *  /usr/local/sbin/congregation-sync-backup
#
# Records in the database are already end-to-end encrypted. The copy is
# encrypted again with age because it still reveals metadata (record counts,
# change times) and holds device-token hashes. Only the age *public* key is
# on the server; keep the private key offline.
#
# Restore:  age -d -i backup-key.txt sync-<stamp>.db.age > sync.db
#           systemctl stop congregation-sync
#           install -o congregation-sync -g congregation-sync -m 600 sync.db /var/lib/congregation-sync/sync.db
#           rm -f /var/lib/congregation-sync/sync.db-wal /var/lib/congregation-sync/sync.db-shm
#           systemctl start congregation-sync
#
# For PostgreSQL, replace the sqlite3 steps with:
#   pg_dump -Fc congregation_sync > "$work/sync.dump"
set -euo pipefail

DATABASE=${DATABASE:-/var/lib/congregation-sync/sync.db}
BACKUP_DIR=${BACKUP_DIR:-/var/backups/congregation-sync}
AGE_RECIPIENTS=${AGE_RECIPIENTS:-/etc/congregation-sync/backup-recipients.txt}
KEEP_DAYS=${KEEP_DAYS:-30}

umask 077
mkdir -p "$BACKUP_DIR"
work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT

stamp=$(date -u +%Y%m%dT%H%M%SZ)
# .backup takes a consistent snapshot while the server keeps running.
sqlite3 "$DATABASE" ".backup '$work/sync.db'"
if [ "$(sqlite3 "$work/sync.db" 'PRAGMA integrity_check;')" != "ok" ]; then
    echo "Integrity check failed; backup not written." >&2
    exit 1
fi

age -R "$AGE_RECIPIENTS" -o "$BACKUP_DIR/sync-$stamp.db.age" "$work/sync.db"
find "$BACKUP_DIR" -name 'sync-*.db.age' -mtime +"$KEEP_DAYS" -delete

# Copy off the server too, e.g. with rclone or restic:
#   rclone copy "$BACKUP_DIR" offsite:congregation-sync-backups
