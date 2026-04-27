FROM ghcr.io/astral-sh/uv:python3.12-bookworm-slim

# Node.js is required only at build time to compile the Hermes React dashboard.
# We strip package-manager caches afterwards to keep the image lean.
RUN apt-get update && \
    apt-get install -y --no-install-recommends curl ca-certificates git unzip && \
    curl -fsSL https://deb.nodesource.com/setup_22.x | bash - && \
    apt-get install -y --no-install-recommends nodejs && \
    rm -rf /var/lib/apt/lists/*

RUN curl -fsSL https://bun.sh/install | BUN_INSTALL=/opt/bun bash && \
    ln -sf /opt/bun/bin/bun /usr/local/bin/bun && \
    ln -sf /opt/bun/bin/bunx /usr/local/bin/bunx

ENV HERMES_SOURCE_DIR=/opt/hermes-agent
ENV HERMES_WEB_DIST=/opt/hermes-agent/web/dist

# Clone Hermes at a pinned commit during the Docker build.
# Railway does not initialise git submodules, so we cannot COPY
# vendor/hermes-agent. Instead we clone and checkout the same SHA that
# the submodule tracks, matching the gstack pattern below.
ARG HERMES_REF=90a3e73daf18448ee5239b1e19d92ded0dbc77ae
RUN git clone https://github.com/NousResearch/hermes-agent.git ${HERMES_SOURCE_DIR} && \
    cd ${HERMES_SOURCE_DIR} && \
    git checkout "$HERMES_REF" && \
    uv pip install --system --no-cache -e ".[all]" && \
    cd ${HERMES_SOURCE_DIR}/web && \
    if [ -f package-lock.json ] || [ -f npm-shrinkwrap.json ]; then npm ci --silent; else npm install --no-audit --no-fund --silent; fi && \
    npm run build && \
    rm -rf ${HERMES_SOURCE_DIR}/.git ${HERMES_SOURCE_DIR}/web/node_modules /root/.npm

# Pin gstack to a known-good commit so each build is reproducible. The
# upstream repo ships without a bun.lockb, so we cannot use
# --frozen-lockfile; the SHA pin is what gives us repeatability instead.
ARG GSTACK_REF=ed1e4be2f68bf977f1fa485eba94d89dbef5255c
RUN git clone https://github.com/garrytan/gstack /opt/gstack && \
    cd /opt/gstack && \
    git checkout "$GSTACK_REF" && \
    bun install && \
    bun run build && \
    rm -rf /opt/gstack/.git /root/.bun

COPY requirements.txt /app/requirements.txt
RUN uv pip install --system --no-cache -r /app/requirements.txt

RUN mkdir -p /data/.hermes

COPY server.py /app/server.py
COPY templates/ /app/templates/
COPY start.sh /app/start.sh
RUN chmod +x /app/start.sh

ENV HOME=/data
ENV HERMES_HOME=/data/.hermes

CMD ["/app/start.sh"]
