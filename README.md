# Hermes Agent — Railway Template

Deploy [Hermes Agent](https://github.com/NousResearch/hermes-agent) on [Railway](https://railway.app) with a web-based admin dashboard for configuration, gateway management, and user pairing.

[![Deploy on Railway](https://railway.com/button.svg)](https://railway.com/deploy/hermes-agent-ai?referralCode=QXdhdr&utm_medium=integration&utm_source=template&utm_campaign=generic)

> Hermes Agent is an autonomous AI agent by [Nous Research](https://nousresearch.com/) that lives on your server, connects to your messaging channels (Telegram, Discord, Slack, etc.), and gets more capable the longer it runs.

<!-- TODO: Add dashboard screenshot -->
<!-- ![Dashboard](docs/dashboard.png) -->

## Features

- **Admin Dashboard** — dark-themed UI to configure providers, channels, tools, and manage the gateway
- **One-Page Setup** — provider dropdown, curated model pickers, checkbox-based channel/tool toggles — no config files to edit
- **Auto-Bootstrap on Fresh Deploys** — empty Railway volumes can seed a default Ollama-compatible provider and auto-start Hermes on first boot
- **Expanded Provider Support** — OpenRouter, OpenAI Codex (OAuth), Factory Droid, and Custom Endpoint providers are all available directly in setup
- **Gateway Management** — start, stop, restart the Hermes gateway from the browser
- **Live Status** — stat cards for gateway state, uptime, model, and pending pairing requests
- **Live Logs** — streaming gateway log viewer
- **User Pairing** — approve or deny users who message your bot, revoke access anytime
- **Slack DM Controls** — configure allowed Slack member IDs and an optional home channel from the dashboard
- **Slack MCP Controls** — enable Slack's official MCP server, expose a native-dashboard helper, and test Railway-friendly header auth without overwriting existing `mcp_servers`
- **Terminal Chat API** — send authenticated one-shot Hermes chat requests over HTTP and resume sessions from the CLI
- **Bundled gstack Skills** — ships with the public `garrytan/gstack` skill bundle prewired as a default external Hermes skills directory
- **Basic Auth** — password-protected admin panel
- **Reset Config** — one-click reset to start fresh

## Getting Started

The easiest way to get started:

### 1. Get an LLM Provider Key (free)

1. Register for free at [OpenRouter](https://openrouter.ai/)
2. Create an API key from your [OpenRouter dashboard](https://openrouter.ai/keys)
3. Pick a free model from the [model list sorted by price](https://openrouter.ai/models?order=pricing-low-to-high) (e.g. `google/gemma-3-1b-it:free`, `meta-llama/llama-3.1-8b-instruct:free`)

### 2. Set Up a Telegram Bot (fastest channel)

Hermes Agent interacts entirely through messaging channels — there is no chat UI like ChatGPT. Telegram is the quickest to set up:

1. Open Telegram and message [@BotFather](https://t.me/BotFather)
2. Send `/newbot`, follow the prompts, and copy the **Bot Token**
3. Send a message to your new bot — it will appear as a pairing request in the admin dashboard
4. To find your Telegram user ID, message [@userinfobot](https://t.me/userinfobot)

### 3. Deploy to Railway

1. Click the **Deploy on Railway** button above
2. Set the `ADMIN_PASSWORD` environment variable (or a random one will be generated and printed to deploy logs)
3. Attach a **volume** mounted at `/data` (persists config across redeploys)
4. Open your app URL — log in with username `admin` and your password

### 4. Configure in the Admin Dashboard

1. **LLM Provider** — select OpenRouter from the dropdown, paste your API key, enter the model name
2. **Messaging Channel** — check Telegram, paste the Bot Token from BotFather
3. Click **Save & Start** — the gateway will start and your bot goes live

> Fresh Railway volumes can auto-seed a default Ollama-compatible provider on first boot.
> Override it with `OLLAMA_HOST`, `OLLAMA_MODEL`, and `OLLAMA_API_KEY` as Railway service variables, or replace it from the dashboard at any time.

### 5. Start Chatting

Message your Telegram bot. If you're a new user, a pairing request will appear in the admin dashboard under **Users** — click **Approve**, and you're in.

<!-- TODO: Add Telegram chat screenshot -->
<!-- ![Telegram Example](docs/telegram-example.png) -->

## Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `PORT` | `8080` | Web server port (set automatically by Railway) |
| `ADMIN_USERNAME` | `admin` | Basic auth username |
| `ADMIN_PASSWORD` | *(auto-generated)* | Basic auth password — if unset, a random password is printed to logs |

All other configuration (LLM provider, model, channels, tools) is managed through the admin dashboard.

## Bundled Default Skills

This image also ships the public [`garrytan/gstack`](https://github.com/garrytan/gstack)
skill bundle as a default external Hermes skill directory. On boot, the repo is
exposed at `~/.claude/skills/gstack` and added to `skills.external_dirs`, so the
gstack skills are available without any manual install step.

## First-Boot Default Provider Seeding

On a brand-new Railway deploy with an empty `/data` volume, `start.sh` can seed
`/data/.hermes/.env` so Hermes is immediately runnable without completing the
setup wizard first. The default seed is aimed at an Ollama-compatible endpoint:

- `LLM_MODEL=gemma4:26b`
- `OPENAI_API_KEY=ollama`
- `OPENAI_BASE_URL=${OLLAMA_HOST}/v1`

Behavior notes:

- Seeding only runs when no saved `LLM_MODEL` exists, so redeploys do not clobber an existing setup.
- You can override the seed with Railway service variables: `OLLAMA_HOST`, `OLLAMA_MODEL`, and `OLLAMA_API_KEY`.
- If your local model is not directly reachable from Railway, use a public tunnel URL for `OLLAMA_HOST`.

## Supported Providers

OpenRouter, DeepSeek, DashScope, GLM / Z.AI, Kimi, MiniMax, HuggingFace,
**OpenAI Codex (OAuth)**,
**Factory Droid**,
**Custom Endpoint** (any OpenAI-compatible API — Ollama, vLLM, llama.cpp, LM Studio, …).

### Using OpenAI Codex OAuth

1. Open the proxied **Hermes Dashboard** (`/?force=1`)
2. Go to **Keys**
3. Connect **OpenAI Codex (ChatGPT)**
4. Return to **Setup**, choose **OpenAI Codex (OAuth)**, pick a model from the dropdown, and save

The wrapper then writes `model.provider: "openai-codex"` into
`/data/.hermes/config.yaml`, so gateway restarts keep using Codex instead of
falling back to `auto` or a stale custom endpoint.

### Using Factory Droid allocation

Select **Factory Droid** in the setup UI, paste a `FACTORY_API_KEY` from
`https://app.factory.ai/settings/api-keys`, and choose a Factory model ID such
as `gpt-5.4-mini`, `gpt-5.4`, `gpt-5.3-codex`, `kimi-k2.5`, or `minimax-m2.5`.

This is not the generic Custom Endpoint flow: the template writes a named
`factory-droid` provider and routes Hermes through a local authenticated bridge
that adds Factory Droid headers before forwarding requests to Factory, so usage
is charged against your Factory plan allocation.

### Using a local model (Ollama / vLLM / LM Studio)

Railway containers cannot reach `localhost` on your machine. To use a model running on
your home PC (e.g. `ollama run gemma4`), expose it via a tunnel and paste the **public**
URL into the Custom Endpoint **Base URL** field in the admin dashboard:

```bash
# Simplest: free, HTTPS-terminated, no account needed
cloudflared tunnel --url http://localhost:11434
# → https://<random>.trycloudflare.com  → append /v1 in the UI
```

Alternatives: `ngrok http 11434`, Tailscale Funnel, or router port-forwarding + DDNS.
The **LLM Model** field must match the ID reported by `GET /v1/models` on your server
(for Ollama, `ollama list`).

## Supported Channels

Telegram, Discord, Slack, WhatsApp, Email, Mattermost, Matrix

### Slack DMs

To make Slack DMs actually reach Hermes, configure these in the dashboard's Slack card:

- **Allowed Member IDs** (`SLACK_ALLOWED_USERS`) — paste your Slack member ID, or use `*` for broad testing
- **Home Channel ID** (`SLACK_HOME_CHANNEL`) — optional default channel for scheduled / cron-style messages

Slack app requirements:

- `im:history`, `im:read`, `im:write` scopes
- `message.im` event subscription
- **Messages Tab** enabled in App Home

If `SLACK_ALLOWED_USERS` is empty, Hermes may treat inbound DMs as unauthorized pairing attempts instead of normal chat messages.

## Supported Tool Integrations

Parallel (search), Firecrawl (scraping), Tavily (search), FAL (image gen), Browserbase, GitHub, OpenAI Voice (Whisper/TTS), Honcho (memory)

## Slack MCP

The setup UI can now enable the official Slack MCP endpoint by generating this
Hermes config entry:

```yaml
mcp_servers:
  slack:
    url: "https://mcp.slack.com/mcp"
    auth: "oauth"
```

Important caveats:

- Slack MCP is separate from the normal Slack bot channel settings.
- After saving, you must complete Hermes's MCP OAuth flow for the `slack`
  server from the runtime/browser flow that Hermes opens or logs.
- Slack currently limits MCP access to internal apps and Slack
  Marketplace-published apps.
- This wrapper now preserves existing `mcp_servers` entries in
  `/data/.hermes/config.yaml` instead of overwriting them on every save.

### Railway-friendly header auth testing

For Railway deployments where localhost callback OAuth is awkward, the setup UI
also supports a direct bearer-token validation path:

1. Paste a Slack MCP user token into **Tool API Keys → Slack MCP User Token**
2. Save the config
3. Click **Test header auth**

When a user token is present, the wrapper also manages this additional Hermes
config entry:

```yaml
mcp_servers:
  slack_header:
    url: "https://mcp.slack.com/mcp"
    headers:
      Authorization: "Bearer ${SLACK_MCP_USER_TOKEN}"
```

The setup test button sends a direct MCP `initialize` request against Slack and
shows the returned HTTP status / error inline, so you can tell the difference
between a missing token, a rejected token (`401`), and a successful MCP
handshake without shelling into the Railway container.

## Architecture

```
Railway Container
├── Python Admin Server (Starlette + Uvicorn)
│   ├── /            — Admin dashboard (Basic Auth)
│   ├── /health      — Health check (no auth)
│   └── /api/*       — Config, status, logs, gateway, pairing
└── hermes gateway   — Managed as async subprocess
```

The admin server runs on `$PORT` and manages the Hermes gateway as a child process. Config is stored in `/data/.hermes/.env` and `/data/.hermes/config.yaml`. Gateway stdout/stderr is captured into a ring buffer and streamed to the Logs panel.

## Running Locally

```bash
docker build -t hermes-agent .
docker run --rm -it -p 8080:8080 -e PORT=8080 -e ADMIN_PASSWORD=changeme -v hermes-data:/data hermes-agent
```

Open `http://localhost:8080` and log in with `admin` / `changeme`.

## Terminal Chat via HTTP

For quick one-shot calls from a terminal, log in once to capture the wrapper
cookie, then POST to the Railway wrapper's chat endpoint:

```bash
BASE="https://your-app.up.railway.app"

curl -sS -c cookies.txt -X POST "$BASE/login" \
  -d "username=admin&password=YOUR_PASSWORD" \
  -o /dev/null

curl -sS -b cookies.txt -X POST "$BASE/api/chat" \
  -H "Content-Type: application/json" \
  -d '{"message":"안녕"}'
```

The response is JSON:

```json
{"ok":true,"response":"...","session_id":"20260426_123456_abcd1234"}
```

You can resume an existing Hermes session by including `"session_id"` (or
`"resume"`), and optionally pass through `"skills"`, `"toolsets"`, `"model"`,
`"provider"`, and `"max_turns"`. Base URL and API keys are configured via the
admin dashboard (`.env`) or Railway service variables, not per-request.

## Recent Updates (PR #1–#11)

- **PR #1 — Custom Endpoint provider**: added first-class support for OpenAI-compatible endpoints such as Ollama, vLLM, llama.cpp, and LM Studio, including Base URL validation and local-model docs.
- **PR #2 — Factory Droid provider**: added a dedicated Factory Droid setup path backed by `FACTORY_API_KEY` and a local authenticated bridge instead of treating it as a generic custom endpoint.
- **PR #3 — First-boot Ollama seeding**: fresh Railway volumes can now seed a default Ollama-compatible provider and auto-start Hermes without manual setup.
- **PR #4 — Slack DM config fix**: exposed `SLACK_ALLOWED_USERS` and `SLACK_HOME_CHANNEL` in the dashboard so Slack DMs and scheduled messages can be configured correctly.
- **PR #5 — Wrapper-backed terminal chat**: added authenticated `POST /api/chat` and `POST /setup/api/chat` endpoints for one-shot Hermes chats and resumable sessions from the CLI.
- **PR #6 — Codex OAuth provider**: added first-class OpenAI Codex (OAuth) setup support and kept Codex selected across config regeneration and restarts.
- **PR #7 — Bundled gstack skills**: vendored the public `garrytan/gstack` bundle into the image and auto-wired it into Hermes as a default external skills directory.
- **PR #8 — Current Hermes CLI compatibility**: fixed the wrapper chat command so `/api/chat` continues to work with the current `hermes chat -Q -q ...` CLI invocation shape.
- **PR #9 — Slack MCP support**: added a setup toggle for the official Slack MCP endpoint and preserved existing `mcp_servers` entries when regenerating Hermes config.
- **PR #10 — Dashboard Slack MCP discoverability**: added a proxied Hermes dashboard helper widget plus higher-contrast dashboard/setup colors so Slack MCP state is easier to find and the UI is more readable.
- **PR #11 — Setup-side Slack MCP header testing**: added `SLACK_MCP_USER_TOKEN`, a managed `slack_header` MCP config entry, and a one-click dashboard test that validates bearer-token auth directly from `/setup`.

## Credits

- [Hermes Agent](https://github.com/NousResearch/hermes-agent) by [Nous Research](https://nousresearch.com/)
- UI inspired by [OpenClaw](https://github.com/praveen-ks-2001/openclaw-railway) admin template
