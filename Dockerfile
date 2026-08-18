# syntax=docker/dockerfile:1
#
# All-in-one image for demos.corynorris.me on Dokku.
#
# Dokku does not check out git submodules in the build context, so each app
# repo is cloned at the pinned commit from docker/submodule-pins.txt and built
# here. The final image bundles nginx (path-based router) plus every backend on
# 127.0.0.1, all supervised by supervisord. video-api is intentionally absent —
# it is not part of the current production stack (not in docker-compose.yml).

# ════════════════════════════════════════════════════════════════════════════
# Fetch — clone every app repo at its pinned commit
# ════════════════════════════════════════════════════════════════════════════
FROM alpine:3.20.3 AS fetch
RUN apk add --no-cache git
ARG GITHUB_BASE=https://github.com/corynorris
COPY docker/submodule-pins.txt /pins.txt
RUN set -eu; \
    while read -r repo sha; do \
        case "${repo}" in ""|\#*) continue ;; esac; \
        echo "==> cloning ${repo} @ ${sha}"; \
        git clone --quiet --filter=blob:none --no-checkout "${GITHUB_BASE}/${repo}.git" "/src/${repo}"; \
        git -C "/src/${repo}" fetch --quiet --depth 1 origin "${sha}"; \
        git -C "/src/${repo}" checkout --quiet --detach FETCH_HEAD; \
        rm -rf "/src/${repo}/.git"; \
    done < /pins.txt

# ════════════════════════════════════════════════════════════════════════════
# Static SPAs (roguelike, life, recipebox, tilemap) — built, then served
# straight from disk by the router nginx.
# ════════════════════════════════════════════════════════════════════════════
FROM node:22-alpine AS static-builder
ENV CI=true
RUN corepack enable && corepack prepare pnpm@10.15.1 --activate && mkdir -p /dist
COPY --from=fetch /src/roguelike /src/roguelike
COPY --from=fetch /src/life /src/life
COPY --from=fetch /src/recipebox /src/recipebox
COPY --from=fetch /src/tilemap /src/tilemap
RUN set -eu; \
    for name in roguelike life recipebox tilemap; do \
        echo "==> building ${name}"; \
        cd "/src/${name}"; \
        rm -f pnpm-workspace.yaml; \
        pnpm install --no-frozen-lockfile --ignore-scripts; \
        pnpm rebuild @swc/core esbuild; \
        pnpm run build; \
        mkdir -p "/dist/${name}"; \
        cp -a dist/. "/dist/${name}/"; \
    done

# ════════════════════════════════════════════════════════════════════════════
# Node apps (voting, chat, comments, shortener, srs)
# ════════════════════════════════════════════════════════════════════════════
FROM node:22-alpine AS node-builder
ENV CI=true
RUN corepack enable && corepack prepare pnpm@10.15.1 --activate && mkdir -p /out
COPY scripts/dokku/set-vite-base.sh /usr/local/bin/set-vite-base.sh
RUN chmod +x /usr/local/bin/set-vite-base.sh

# ── voting (Express + Socket.IO) → 8090 ──────────────────────────────────────
COPY --from=fetch /src/voting-app-react /src/voting-app-react
WORKDIR /src/voting-app-react
RUN rm -f pnpm-workspace.yaml && \
    pnpm install --no-frozen-lockfile --ignore-scripts && \
    pnpm rebuild @swc/core esbuild && \
    set-vite-base.sh /voting/ && \
    sed -i "s|io(SOCKET_URL, {|io(SOCKET_URL, { path: '/voting/socket.io',|" src/socket.ts && \
    pnpm run build && \
    sed -i "s|new Server(httpServer, {|new Server(httpServer, { path: '/voting/socket.io',|" dist-server/server/index.js && \
    mkdir -p /out/voting && cp -a package.json pnpm-lock.yaml /out/voting/ && \
    cp -a dist /out/voting/dist && cp -a dist-server /out/voting/dist-server
RUN cd /out/voting && pnpm install --no-frozen-lockfile --prod --ignore-scripts

# ── chat (Express + Socket.IO) → 3000 ────────────────────────────────────────
COPY --from=fetch /src/socket-io-chat-app /src/socket-io-chat-app
WORKDIR /src/socket-io-chat-app
RUN rm -f pnpm-workspace.yaml && \
    pnpm install --no-frozen-lockfile --ignore-scripts && \
    pnpm rebuild @swc/core esbuild && \
    set-vite-base.sh /chat/ && \
    sed -i "s|const socket: Socket = io();|const socket: Socket = io({ path: '/chat/socket.io' });|" src/socket.ts && \
    pnpm run build && \
    sed -i "s|new Server(http);|new Server(http, { path: '/chat/socket.io' });|" dist/server/index.js && \
    mkdir -p /out/chat && cp -a package.json pnpm-lock.yaml /out/chat/ && \
    cp -a dist /out/chat/dist
RUN cd /out/chat && pnpm install --no-frozen-lockfile --prod --ignore-scripts

# ── comments (Express + PG) → 3001 ───────────────────────────────────────────
COPY --from=fetch /src/react-comment-box /src/react-comment-box
WORKDIR /src/react-comment-box
RUN rm -f pnpm-workspace.yaml && \
    pnpm install --no-frozen-lockfile --ignore-scripts && \
    pnpm rebuild @swc/core esbuild && \
    set-vite-base.sh /comments/ && \
    pnpm run build && \
    mkdir -p /out/comments && cp -a package.json pnpm-lock.yaml /out/comments/ && \
    cp -a dist /out/comments/dist
RUN cd /out/comments && pnpm install --no-frozen-lockfile --prod --ignore-scripts

# ── shortener (Express + PG) → 3002 ──────────────────────────────────────────
COPY --from=fetch /src/url-shortener /src/url-shortener
WORKDIR /src/url-shortener
RUN rm -f pnpm-workspace.yaml && \
    pnpm install --no-frozen-lockfile --ignore-scripts && \
    pnpm rebuild @swc/core esbuild && \
    pnpm run build && \
    mkdir -p /out/shortener && cp -a package.json pnpm-lock.yaml /out/shortener/ && \
    cp -a dist /out/shortener/dist && cp -a public /out/shortener/public
RUN cd /out/shortener && pnpm install --no-frozen-lockfile --prod --ignore-scripts

# ── srs (SvelteKit + drizzle) → 3005 ─────────────────────────────────────────
COPY --from=fetch /src/spaced-repitition /src/spaced-repitition
WORKDIR /src/spaced-repitition
ENV BASE_PATH=/srs
RUN pnpm install --frozen-lockfile && \
    pnpm run build && \
    mkdir -p /out/srs && \
    cp -a package.json /out/srs/ && \
    cp -a node_modules /out/srs/node_modules && \
    cp -a build /out/srs/build && \
    cp -a drizzle /out/srs/drizzle && \
    cp -a drizzle.config.ts /out/srs/ && \
    cp -a docker-entrypoint.sh /out/srs/

# ════════════════════════════════════════════════════════════════════════════
# Trello (Elixir/Phoenix) → 4000
# ════════════════════════════════════════════════════════════════════════════
FROM hexpm/elixir:1.17.3-erlang-27.1-alpine-3.20.3 AS trello-builder
RUN apk add --no-cache build-base && mix local.hex --force && mix local.rebar --force
COPY --from=fetch /src/trello /app
WORKDIR /app
RUN mix deps.get
ARG SECRET_KEY_BASE=dummy-key-base-for-compile-only
ARG SECRET_KEY=dummy-secret-for-compile-only
ENV SECRET_KEY_BASE=${SECRET_KEY_BASE} \
    SECRET_KEY=${SECRET_KEY} \
    DATABASE_URL=ecto://dummy:dummy@localhost/trello
RUN MIX_ENV=prod mix compile

FROM node:22-alpine AS trello-assets
WORKDIR /app
COPY --from=fetch /src/trello/assets/package.json /src/trello/assets/package-lock.json ./
RUN npm ci --ignore-scripts
COPY --from=fetch /src/trello/assets/ ./
ARG PUBLIC_URL=/trello
ENV PUBLIC_URL=${PUBLIC_URL}
RUN npx webpack --mode production

# ════════════════════════════════════════════════════════════════════════════
# Runtime — nginx router + all backends, supervised
# ════════════════════════════════════════════════════════════════════════════
FROM hexpm/elixir:1.17.3-erlang-27.1-alpine-3.20.3
RUN apk add --no-cache nginx nodejs npm supervisor openssl ncurses-libs libstdc++ && \
    mkdir -p /app /usr/share/nginx/html

# nginx (main config + path router)
COPY docker/nginx.conf /etc/nginx/nginx.conf
COPY docker/nginx-dokku.conf /etc/nginx/conf.d/default.conf

# static SPAs served directly by nginx
COPY --from=static-builder /dist /usr/share/nginx/html

# node backends
COPY --from=node-builder /out/voting /app/voting
COPY --from=node-builder /out/chat /app/chat
COPY --from=node-builder /out/comments /app/comments
COPY --from=node-builder /out/shortener /app/shortener
COPY --from=node-builder /out/srs /app/srs

# trello (compiled app + assets)
COPY --from=trello-builder /app /app/trello
COPY --from=trello-builder /root/.mix /root/.mix
COPY --from=trello-assets /priv/static /app/trello/priv/static

# supervisord + per-app start scripts
COPY docker/supervisord.conf /etc/supervisord.conf
COPY docker/bin/ /usr/local/bin/
RUN chmod +x /usr/local/bin/start-*.sh /app/srs/docker-entrypoint.sh

EXPOSE 80
CMD ["/usr/bin/supervisord", "-c", "/etc/supervisord.conf"]
