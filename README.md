# Demos

Umbrella repository for all demo apps, deployed as a single image to **Dokku** at
<https://demos.corynorris.me>. Every app lives in its own repo and is pulled in as a git
submodule.

## Apps

| App | Path | Stack | DB |
|---|---|---|---|
| roguelike | `/roguelike` | React + Vite (static) | — |
| life | `/life` | React + Vite (static) | — |
| recipebox | `/recipebox` | React + Vite (static) | — |
| tilemap | `/tilemap` | React + Vite (static) | — |
| voting-app-react | `/voting` | React + Express + Socket.IO | — |
| socket-io-chat-app | `/chat` | React + Express + Socket.IO | — |
| react-comment-box | `/comments` | React + Express | PostgreSQL |
| url-shortener | `/s` | Express + TypeScript | PostgreSQL |
| spaced-repitition | `/srs` | SvelteKit + drizzle | PostgreSQL |
| trello | `/trello` | Elixir/Phoenix + Preact | PostgreSQL |

`video-api` is still a submodule, but it is **not deployed**: it is absent from the root
`Dockerfile` and the nginx router.

## Architecture

```
demos.corynorris.me
         │
   Cloudflare tunnel
         │
    ┌────┴────────────── demos container ──────────────────┐
    │  nginx path router  (/roguelike, /chat, /s, …)        │
    │  supervisord → backends on 127.0.0.1:3000-8090        │
    │  static SPAs served straight from disk                │
    └────┬──────────────────────────────────────────────────┘
         │
   dokku postgres:demos-db  (comments, url_shortener,
                             spaced_repetition, trello)
```

- The root `Dockerfile` builds everything in one image: static SPAs, the Node backends
  (voting, chat, comments, shortener, srs) and the Phoenix app (trello).
- nginx strips the app prefix (`/chat/…` → `/`), so apps stay unaware of their mount point.
- Socket.IO apps use namespaced paths (`/voting/socket.io`, `/chat/socket.io`), patched in at
  build time by the root `Dockerfile`.
- PostgreSQL is the shared `dokku postgres:demos-db` service.

## Deploying

Dokku does **not** check out submodules, so the image is built from the SHAs listed in
[`docker/submodule-pins.txt`](docker/submodule-pins.txt) instead of the submodule pointers.
Bumping a submodule without bumping the pins deploys the old app code — `update-submodules.sh`
regenerates the pins for you.

```bash
./update-submodules.sh          # bumps submodules AND rewrites docker/submodule-pins.txt
git commit -m "chore: update submodules to latest"
git push origin main
git push dokku main             # builds and deploys
```

The `dokku` remote is `dokku-deploy:demos` (ssh alias `dokku-deploy`, ProxyJump via
`ubuntu-server`). First-time setup:

```bash
git remote add dokku dokku-deploy:demos
ssh dokku-deploy postgres:create demos-db   # only once
```

### Application config

Secrets and DB URLs live in Dokku, not in this repo:

```bash
ssh dokku-deploy config:show demos
ssh dokku-deploy config:set demos BASE_URL=https://demos.corynorris.me/s
ssh dokku-deploy logs demos --tail
ssh dokku-deploy ps:restart demos
```

| Variable | Description |
|---|---|
| `BASE_URL` | URL shortener public base (`https://demos.corynorris.me/s`) |
| `BETTER_AUTH_URL` / `BETTER_AUTH_SECRET` | spaced-repitition auth |
| `DATABASE_URL` | spaced-repitition PG URL |
| `SRS_DATABASE_URL` | aliased to `DATABASE_URL` by `docker/bin/srs` |
| `COMMENTS_DATABASE_URL` | react-comment-box PG URL |
| `SHORTENER_DATABASE_URL` | url-shortener PG URL |
| `TRELLO_DATABASE_URL` | trello PG URL |
| `TRELLO_SECRET_KEY_BASE` / `TRELLO_SECRET_KEY` | Phoenix secret, Guardian JWT secret |
| `DOMAIN` | Public domain (`demos.corynorris.me`) |

`VIDEO_*` variables are legacy: `video-api` is not part of the deployed stack.

## Local development

`docker-compose.yml` is a **local-dev only** stack (the Dokploy deployment it was originally
written for has been retired).

```bash
git clone --recurse-submodules https://github.com/corynorris/demos.git
cd demos

cp .env.example .env            # or ./scripts/gen-prod-env.sh for generated secrets
docker compose up -d --build
# http://localhost
```

## Scripts

| Script | Purpose |
|---|---|
| `update-submodules.sh` | Bump every submodule and regenerate `docker/submodule-pins.txt` |
| `scripts/gen-prod-env.sh` | Interactive `.env` generator (local compose) |
| `scripts/init-multi-db.sh` | Create the per-app databases in a fresh Postgres |
| `scripts/dokku/set-vite-base.sh` | Patch an app's Vite `base` at image-build time |
