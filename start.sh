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
if [ ! -f "$ENV_FILE" ]; then
  touch "$ENV_FILE"
fi

# Only seed when neither the host environment nor the persistent .env already
# defines LLM_MODEL. This ensures Railway service variables (LLM_MODEL,
# OPENAI_API_KEY, OPENAI_BASE_URL, etc.) are respected and never silently
# overwritten by our defaults.
if [ -z "$LLM_MODEL" ] && ! grep -q "^LLM_MODEL=" "$ENV_FILE"; then
  OLLAMA_HOST="${OLLAMA_HOST:-http://localhost:11434}"
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
  } >> "$ENV_FILE"

  # Don't clobber explicit OPENAI_* values from host env or .env — only seed
  # the OpenAI-compatible endpoint vars when they're not already provided.
  if [ -z "$OPENAI_API_KEY" ] && ! grep -q "^OPENAI_API_KEY=" "$ENV_FILE"; then
    {
      echo ""
      echo "# Providers"
      echo "OPENAI_API_KEY=$OLLAMA_API_KEY"
    } >> "$ENV_FILE"
  fi
  if [ -z "$OPENAI_BASE_URL" ] && ! grep -q "^OPENAI_BASE_URL=" "$ENV_FILE"; then
    echo "OPENAI_BASE_URL=$BASE" >> "$ENV_FILE"
  fi

  echo "[start] Seeded default Ollama provider: model=$OLLAMA_MODEL base_url=$BASE" >&2
fi

exec python /app/server.py
