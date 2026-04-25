#!/bin/bash
set -e

# Mirror dashboard-ref-only's startup: create every directory hermes expects
# and seed a default config.yaml if the volume is empty. Without these,
# `hermes dashboard` endpoints that hit logs/, sessions/, cron/, etc. can fail
# with opaque errors even though no auth is actually involved.
mkdir -p /data/.hermes/cron /data/.hermes/sessions /data/.hermes/logs \
         /data/.hermes/memories /data/.hermes/skills /data/.hermes/pairing \
         /data/.hermes/hooks /data/.hermes/image_cache /data/.hermes/audio_cache \
         /data/.hermes/workspace

if [ ! -f /data/.hermes/config.yaml ] && [ -f /opt/hermes-agent/cli-config.yaml.example ]; then
  cp /opt/hermes-agent/cli-config.yaml.example /data/.hermes/config.yaml
fi

# Seed default provider (Ollama @ home PC, gemma4:26b) on first boot so the
# gateway auto-starts immediately after a Railway deploy. Skipped if .env
# already configures LLM_MODEL — the admin UI / persistent volume wins.
# Override via Railway service variables: OLLAMA_HOST, OLLAMA_MODEL, OLLAMA_API_KEY.
ENV_FILE=/data/.hermes/.env
mkdir -p "$(dirname "$ENV_FILE")"
[ ! -f "$ENV_FILE" ] && touch "$ENV_FILE"

if ! grep -q "^LLM_MODEL=" "$ENV_FILE"; then
  OLLAMA_HOST="${OLLAMA_HOST:-http://100.115.26.75:11434}"
  OLLAMA_MODEL="${OLLAMA_MODEL:-gemma4:26b}"
  OLLAMA_API_KEY="${OLLAMA_API_KEY:-ollama}"

  # Strip trailing slash and ensure /v1 suffix for OpenAI-compatible endpoint.
  BASE="${OLLAMA_HOST%/}"
  case "$BASE" in
    */v1) ;;
    *) BASE="$BASE/v1" ;;
  esac

  {
    echo "# Model"
    echo "LLM_MODEL=$OLLAMA_MODEL"
    echo ""
    echo "# Providers"
    echo "OPENAI_API_KEY=$OLLAMA_API_KEY"
    echo "OPENAI_BASE_URL=$BASE"
  } >> "$ENV_FILE"

  echo "[start] Seeded default Ollama provider: model=$OLLAMA_MODEL base_url=$BASE" >&2
fi

exec python /app/server.py
