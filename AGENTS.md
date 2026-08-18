# Demos Monorepo — Agent Notes

## Deployment targets

- **Dokku** (primary): app `demos` on the dokku server, public URL
  `https://demos.corynorris.me` (TLS terminated upstream by Cloudflare; the app
  serves plain HTTP on port 80).
  - Deploy: `git push dokku main` (remote is `dokku:demos`; `~/.ssh/config`
    alias `dokku` uses the deploy key).
  - The root `Dockerfile` builds one all-in-one container: nginx path router +
    all backends on 127.0.0.1, supervised by supervisord.
  - **Submodule pins**: Dokku does not check out submodules, so the Dockerfile
    clones each app repo at the commit listed in `docker/submodule-pins.txt`.
    When bumping a submodule, update that file too (same SHAs as
    `git submodule status`).
  - App env (DB URLs, Phoenix/SvelteKit secrets) is set via
    `dokku config:set demos ...`; per-backend start scripts in `docker/bin/`
    map prefixed vars (e.g. `COMMENTS_DATABASE_URL`) to each process.
  - Postgres: dokku postgres service `demos-db` (linked to app), databases
    `comments`, `url_shortener`, `spaced_repetition`, `trello`.
  - `video-api` is not deployed (absent from docker-compose.yml and
    docker/nginx-dokku.conf).

- **Dokploy** (legacy): see README.md. Keep docker-compose.yml working.
