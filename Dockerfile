FROM ghcr.io/astral-sh/uv:python3.12-bookworm-slim

# Node.js is required only at build time to compile the Hermes React dashboard.
# We strip the source + apt lists afterwards to keep the image lean.
RUN apt-get update && \
    apt-get install -y --no-install-recommends curl ca-certificates git unzip && \
    curl -fsSL https://deb.nodesource.com/setup_22.x | bash - && \
    apt-get install -y --no-install-recommends nodejs && \
    rm -rf /var/lib/apt/lists/*

RUN curl -fsSL https://bun.sh/install | BUN_INSTALL=/opt/bun bash && \
    ln -sf /opt/bun/bin/bun /usr/local/bin/bun && \
    ln -sf /opt/bun/bin/bunx /usr/local/bin/bunx

# Install hermes-agent (provides the `hermes` CLI) and pre-build its React
# dashboard so `hermes dashboard` has nothing to build at runtime.
# Deleting web/ afterwards makes hermes's internal _build_web_ui skip the
# rebuild step (it early-returns when package.json is absent), so container
# startup is fast and no runtime npm dependency is needed.
RUN git clone --depth 1 https://github.com/NousResearch/hermes-agent.git /opt/hermes-agent && \
    cd /opt/hermes-agent && \
    uv pip install --system --no-cache -e ".[all]" && \
    cd /opt/hermes-agent/web && \
    npm install --silent && \
    npm run build && \
    rm -rf /opt/hermes-agent/web /opt/hermes-agent/.git /root/.npm

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
