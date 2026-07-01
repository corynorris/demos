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
demos.corynorris.me
         │
    ┌────┴────┐
    │  Caddy   │  (reverse proxy + automatic HTTPS)
    └────┬────┘
         │
    ┌────┼──────────────────────────────┐
    │    │         Services              │
    │ roguelike  life  recipebox         │    Static SPAs (nginx)
    │ voting  chat  comments  shortener  │    Node.js (Express)
    │ srs-api  srs-web                  │    Rust + nginx
    │ video                             │    Elixir/Phoenix
    │ postgres  mongo                   │    Databases
    └───────────────────────────────────┘
```

## Requirements

- Docker + Docker Compose
- pnpm (for local development)
- Dokploy (for deployment)

## Quick Start (Local)

```bash
# Clone with submodules
git clone --recurse-submodules https://github.com/corynorris/demos.git
cd demos

# Copy env file
cp .env.example .env
# Edit .env and set VIDEO_SECRET_KEY_BASE / VIDEO_SECRET_KEY

# Build and start all services
docker compose up -d --build

# Open http://localhost
```

## Environment Variables

| Variable | Required | Default | Description |
|---|---|---|---|
| `DB_PASSWORD` | No | `demos` | PostgreSQL password |
| `VIDEO_SECRET_KEY_BASE` | Yes | — | Phoenix secret key base (64+ bytes) |
| `VIDEO_SECRET_KEY` | Yes | — | Guardian JWT secret key |
| `BASE_URL` | No | Auto | URL shortener base URL |

Generate secrets for video-api:
```bash
cd apps/video-api
mix phx.gen.secret
```

## Deploying to Dokploy

1. Add this repository to Dokploy as a new project
2. Set the Docker Compose path to `docker-compose.yml`
3. Configure the environment variables from `.env.example`
4. Set the domain to `demos.corynorris.me`
5. Deploy

Dokploy will automatically provision SSL certificates via Caddy.

## Updating Submodules

```bash
# Update all submodules to latest main
git submodule update --remote

# Update a specific submodule
cd apps/roguelike
git pull origin main
cd ../..
git add apps/roguelike
git commit -m "chore: update roguelike submodule"

# Push changes
git push origin main
```

## Development

Each app can be developed independently in its own repo. After merging changes
to the app's `main` branch, update the submodule pointer in this repo.

```bash
# Develop locally
cd apps/voting-app-react
pnpm install
pnpm dev  # starts Vite + Express
```

## Updating Dependencies

```bash
# In each submodule
cd apps/<app>
pnpm update
pnpm run build
pnpm run lint
pnpm run format

# For Rust
cd apps/spaced-repitition/api
cargo update

# For Elixir
cd apps/video-api
mix deps.update --all
```
