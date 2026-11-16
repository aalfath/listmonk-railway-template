#!/bin/sh
# Start listmonk on Railway: map Railway's Postgres variables to listmonk's
# env config, install the schema on first boot, run migrations on updates,
# then start the server.
set -e

export LISTMONK_app__address="0.0.0.0:${PORT:-9000}"
export LISTMONK_db__host="${LISTMONK_db__host:-${PGHOST:-localhost}}"
export LISTMONK_db__port="${LISTMONK_db__port:-${PGPORT:-5432}}"
export LISTMONK_db__user="${LISTMONK_db__user:-${PGUSER:-listmonk}}"
export LISTMONK_db__password="${LISTMONK_db__password:-${PGPASSWORD:-listmonk}}"
export LISTMONK_db__database="${LISTMONK_db__database:-${PGDATABASE:-listmonk}}"
export LISTMONK_db__ssl_mode="${LISTMONK_db__ssl_mode:-disable}"
export LISTMONK_db__max_open="${LISTMONK_db__max_open:-25}"
export LISTMONK_db__max_idle="${LISTMONK_db__max_idle:-25}"
export LISTMONK_db__max_lifetime="${LISTMONK_db__max_lifetime:-300s}"
export TZ="${TZ:-Etc/UTC}"

# psql reads these.
export PGHOST="$LISTMONK_db__host" PGPORT="$LISTMONK_db__port" \
       PGUSER="$LISTMONK_db__user" PGPASSWORD="$LISTMONK_db__password" \
       PGDATABASE="$LISTMONK_db__database"

echo "railway-start: waiting for Postgres at ${PGHOST}:${PGPORT}"
i=0
until nc -z -w 2 "$PGHOST" "$PGPORT" 2>/dev/null; do
  i=$((i + 1))
  if [ "$i" -ge 60 ]; then
    echo "railway-start: Postgres did not answer after 120 s" >&2
    exit 1
  fi
  sleep 2
done

# --install --idempotent only installs on an empty database. It creates the
# super admin from LISTMONK_ADMIN_USER / LISTMONK_ADMIN_PASSWORD on that first
# install only; changing them later has no effect.
./listmonk --install --idempotent --yes --config ''
./listmonk --upgrade --yes --config ''

# Point listmonk's root URL (used in links in e-mails) at the public domain,
# but only while it still has the install default, so a value set later in
# Settings is never overwritten.
ROOT_URL="${LISTMONK_ROOT_URL:-}"
if [ -z "$ROOT_URL" ] && [ -n "${RAILWAY_PUBLIC_DOMAIN:-}" ]; then
  ROOT_URL="https://${RAILWAY_PUBLIC_DOMAIN}"
fi
if [ -n "$ROOT_URL" ] && command -v psql >/dev/null 2>&1; then
  psql -v ON_ERROR_STOP=1 -q -v url="$ROOT_URL" <<'SQL' || echo "railway-start: could not set root URL" >&2
UPDATE settings SET value = to_jsonb(:'url'::text), updated_at = NOW()
 WHERE key = 'app.root_url' AND value = '"http://localhost:9000"'::jsonb;
SQL
fi

exec ./listmonk --config ''
