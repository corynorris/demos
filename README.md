# Demos Monorepo

Umbrella repository for all demo apps, deployed via **Dokploy** to `demos.corynorris.me`.

## Apps

| App | Path | Stack | DB |
|---|---|---|---|
| roguelike | `/roguelike` | React + Vite (static) | — |
| life | `/life` | React + Vite (static) | — |
| recipebox | `/recipebox` | React + Vite (static) | — |
| voting-app-react | `/voting` | React + Express + Socket.IO | — |
| socket-io-chat-app | `/chat` | React + Express + Socket.IO | — |
| react-comment-box | `/comments` | React + Express | SQLite |
| url-shortener | `/s` | Express + TypeScript | MongoDB |
| spaced-repitition | `/srs` | Rust/Axum + React | PostgreSQL |
| video-api | `/video` | Elixir/Phoenix | PostgreSQL |

## Architecture

```
                     Cloudflare Tunnel (TLS)
                              │
                    dokploy-network (shared)
                              │
                        ┌─────┴─────┐
                        │   Caddy    │  :80 HTTP only
                        └─────┬─────┘
                              │
                    ┌─────────┼─────────────────────────┐
                    │   internal network                 │
                    │                                    │
                    │  roguelike  life  recipebox        │
                    │  voting  chat  comments  shortener │
                    │  srs-api  srs-web  video           │
                    │  db (postgres)  mongo              │
                    └────────────────────────────────────┘
```

- **Cloudflare Tunnel** terminates TLS and routes `demos.corynorris.me` to Caddy
- **Caddy** reverse-proxies HTTP by path to each app container
- **PostgreSQL** is shared (init script creates `spaced_repetition` and `video_api` DBs)
- **MongoDB** for url-shortener only

## Quick Start

### Local dev

```bash
git clone --recurse-submodules https://github.com/corynorris/demos.git
cd demos

# Generate env
cp .env.example .env
# EDIT .env — set POSTGRES_PASSWORD, VIDEO_SECRET_KEY_BASE, VIDEO_SECRET_KEY

docker compose up -d --build
# Open http://localhost
```

### Production deploy on Dokploy

```bash
# 1. Generate production .env
./scripts/gen-prod-env.sh

# 2. Paste output into Dokploy → Project → Environment variables

# 3. Set up Cloudflare Tunnel (one-time)
#    In Cloudflare Zero Trust dashboard:
#      Public Hostname: demos.corynorris.me
#      Service:        http://caddy:80
#    Make sure the tunnel connector can reach Caddy on dokploy-network.

# 4. Deploy — git push to main, Dokploy auto-redeploys
```

## Environment Variables

| Variable | Required | Auto? | Description |
|---|---|---|---|
| `POSTGRES_USER` | No | — | `demos` |
| `POSTGRES_PASSWORD` | **Yes** | gen-prod-env | Shared PG password. Do NOT change after first deploy. |
| `BASE_URL` | No | — | URL shortener base URL |
| `DATABASE_URL` | No | — | SRS Rust API PG connection |
| `VIDEO_SECRET_KEY_BASE` | **Yes** | gen-prod-env | Phoenix secret (64 hex bytes) |
| `VIDEO_SECRET_KEY` | **Yes** | gen-prod-env | Guardian JWT secret (32 hex bytes) |
| `DOMAIN` | No | — | Public domain |

Run `./scripts/gen-prod-env.sh` to generate all secrets automatically.

## Updating Submodules

```bash
# Update all submodules to latest main
git submodule update --remote

# Or update a specific one
cd apps/roguelike && git pull origin main && cd ../..
git add apps/roguelike
git commit -m "chore: update roguelike"

git push origin main  # Dokploy redeploys
```

## Development

Each app is a git submodule. Develop in its own repo, merge to `main`, then
update the submodule pointer here.

```bash
cd apps/voting-app-react
pnpm install && pnpm dev
```
