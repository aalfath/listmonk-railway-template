[![Deploy on Railway](https://railway.com/button.svg)](https://railway.com/new/template/listmonk-4?utm_medium=integration&utm_source=button&utm_campaign=listmonk)

# listmonk on Railway

This repo packages [listmonk](https://listmonk.app), the self-hosted newsletter and mailing list manager, as a Railway template.

- **App:** listmonk **v6.2.0**, from the official image `listmonk/listmonk:v6.2.0@sha256:f535d59e14991337a9f2d570273685378ae86b0d7698c3e00da444e3bc205286` (pinned by version and digest in the `Dockerfile`).
- **Services:** `listmonk` (built from this repo, public) and Railway's `Postgres`.
- **Storage:** listmonk's media uploads live on a volume at `/listmonk/uploads`. Subscribers, lists, campaigns and settings live in Postgres.

## What the wrapper does

`start.sh` runs before listmonk:

1. maps Railway's Postgres variables (`PGHOST`, `PGPORT`, `PGUSER`, `PGPASSWORD`, `PGDATABASE`) to listmonk's `LISTMONK_db__*` settings and listens on `PORT` (default 9000);
2. waits for Postgres;
3. runs `./listmonk --install --idempotent --yes` (installs the schema and creates the super admin only on an empty database) and `./listmonk --upgrade --yes` (runs migrations after an update);
4. sets listmonk's **Root URL** to `https://$RAILWAY_PUBLIC_DOMAIN`, but only while it still has the install default `http://localhost:9000`;
5. starts the server. The health check path is `/health`.

## Variables

| Variable | Default | Notes |
|---|---|---|
| `LISTMONK_ADMIN_USER` | `admin` | Super admin user name, created on first boot only |
| `LISTMONK_ADMIN_PASSWORD` | generated secret | Super admin password, created on first boot only. Change it later in listmonk under Users |
| `PGHOST`, `PGPORT`, `PGUSER`, `PGPASSWORD`, `PGDATABASE` | references to `Postgres` | Database connection over Railway's private network |
| `PORT` | `9000` | Port listmonk listens on |

Optional: `LISTMONK_ROOT_URL` overrides the root URL on first boot (for a custom domain you can also change it later in Settings → General). SMTP servers, bounce handling and media storage (S3) are set in listmonk's own Settings page after you log in.

## Updates

Railway notifies everyone who deployed this template when a change is merged to `main` of this repo. Each version bump changes the pinned image in the `Dockerfile` and adds an entry to [`CHANGELOG.md`](CHANGELOG.md), with breaking changes first. Read it before you apply an update: listmonk runs its database migrations on start (`--upgrade`), so take a Postgres backup first.

## Upstream

- listmonk docs: https://listmonk.app/docs/
- Installation: https://listmonk.app/docs/installation/
- Releases: https://github.com/knadh/listmonk/releases

listmonk is AGPL-3.0 software by Kailash Nadh and contributors. This repo only contains the Railway wrapper.
