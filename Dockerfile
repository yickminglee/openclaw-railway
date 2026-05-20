FROM node:24-bookworm

RUN apt-get update \
  && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
    ca-certificates \
    curl \
    git \
    gosu \
    procps \
    python3 \
    build-essential \
    zip \
    tini \
  && rm -rf /var/lib/apt/lists/*

RUN npm install -g openclaw@latest clawhub@latest

RUN mkdir -p /openclaw \
  && ln -sfn /usr/local/lib/node_modules/openclaw/dist /openclaw/dist

WORKDIR /app

COPY package.json pnpm-lock.yaml ./
RUN npm install -g pnpm@10 && pnpm install --prod

COPY src ./src
COPY --chmod=755 entrypoint.sh ./entrypoint.sh

RUN groupadd -g 1001 openclaw \
  && useradd -m -u 1001 -g 1001 -s /bin/bash openclaw \
  && mkdir -p /data/.openclaw /home/linuxbrew/.linuxbrew \
  && chown -R 1001:1001 /app /data /home/linuxbrew

USER 1001:1001
RUN NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

ENV PATH="/home/linuxbrew/.linuxbrew/bin:/home/linuxbrew/.linuxbrew/sbin:${PATH}"
ENV HOMEBREW_PREFIX="/home/linuxbrew/.linuxbrew"
ENV HOMEBREW_CELLAR="/home/linuxbrew/.linuxbrew/Cellar"
ENV HOMEBREW_REPOSITORY="/home/linuxbrew/.linuxbrew/Homebrew"

ENV PORT=8080
ENV OPENCLAW_ENTRY=/usr/local/lib/node_modules/openclaw/dist/entry.js
EXPOSE 8080

HEALTHCHECK --interval=30s --timeout=5s --start-period=10s \
  CMD curl -f http://localhost:8080/setup/healthz || exit 1

ENTRYPOINT ["./entrypoint.sh"]