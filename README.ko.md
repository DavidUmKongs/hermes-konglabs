# Hermes Agent — Railway 템플릿 (한국어)

Deploy [Hermes Agent](https://github.com/NousResearch/hermes-agent) on [Railway](https://railway.app) with a web-based admin dashboard for configuration, gateway management, and user pairing.

[![Deploy on Railway](https://railway.com/button.svg)](https://railway.com/deploy/hermes-agent-ai?referralCode=QXdhdr&utm_medium=integration&utm_source=template&utm_campaign=generic)

> Hermes Agent는 [Nous Research](https://nousresearch.com/)가 만든 자율형 AI 에이전트입니다. 서버에서 상시 동작하며 Telegram, Discord, Slack 같은 메시징 채널에 연결되고, 오래 운영할수록 더 강력해집니다.

<p>
  <a href="./README.md">
    <img alt="English README - Railway Wrapper Guide" src="https://img.shields.io/badge/English-Railway%20Wrapper%20Guide-111827?style=for-the-badge">
  </a>
  <a href="./README.ko.md">
    <img alt="Korean README - 한국어 가이드" src="https://img.shields.io/badge/한국어-가이드-0f766e?style=for-the-badge">
  </a>
  <a href="https://github.com/NousResearch/hermes-agent#readme">
    <img alt="Upstream Hermes README" src="https://img.shields.io/badge/Upstream-Hermes%20README-2563eb?style=for-the-badge">
  </a>
</p>

위 링크를 탭처럼 사용하면 됩니다.  
- 이 문서: 한국어 Railway wrapper 가이드  
- English README: 영문 wrapper 가이드  
- Upstream Hermes README: Hermes 본체 기능/공식 문서

## 주요 기능

- **Admin Dashboard** — 다크 테마 기반의 설정 UI
- **One-Page Setup** — provider/model/channel/tool을 한 화면에서 설정
- **Auto-Bootstrap on Fresh Deploys** — 빈 Railway 볼륨에서 기본 provider 자동 시드
- **Expanded Provider Support** — OpenRouter, OpenAI Codex (OAuth), Factory Droid, Custom Endpoint 지원
- **Gateway Management** — 브라우저에서 gateway start / stop / restart
- **Live Status** — gateway 상태, uptime, model, pending pairing 요청 표시
- **Live Logs** — 실시간 로그 확인
- **User Pairing** — 메시지를 보낸 사용자 승인/거부/권한 회수
- **Slack DM Controls** — Slack DM 허용 사용자/홈 채널 설정
- **Slack MCP Controls** — 공식 Slack MCP 활성화, native dashboard helper, Railway 친화적인 header auth 테스트 지원
- **Terminal Chat API** — HTTP를 통한 one-shot Hermes chat / session resume
- **Bundled gstack Skills** — `garrytan/gstack` 스킬 번들을 기본 외부 skill 디렉터리로 포함
- **Pinned Hermes Upstream** — `NousResearch/hermes-agent`를 git submodule로 추적해 upstream bump를 리뷰 가능하게 유지
- **Basic Auth** — 비밀번호 보호 admin panel
- **Reset Config** — 저장된 설정 초기화

## 빠른 시작

### 1. LLM Provider 키 준비

1. [OpenRouter](https://openrouter.ai/) 가입
2. [OpenRouter dashboard](https://openrouter.ai/keys) 에서 API key 생성
3. 무료 모델 하나 선택  
   예: `google/gemma-3-1b-it:free`, `meta-llama/llama-3.1-8b-instruct:free`

### 2. Telegram Bot 준비

Hermes Agent는 ChatGPT처럼 자체 채팅 UI가 아니라 **메시징 채널**을 통해 동작합니다. 가장 빠른 시작 경로는 Telegram입니다.

1. Telegram에서 [@BotFather](https://t.me/BotFather)에게 메시지 전송
2. `/newbot` 실행 후 **Bot Token** 복사
3. 새 봇에 메시지를 보내면 admin dashboard에 pairing 요청이 나타남
4. Telegram user ID는 [@userinfobot](https://t.me/userinfobot)에서 확인 가능

### 3. Railway 배포

1. 위의 **Deploy on Railway** 버튼 클릭
2. `ADMIN_PASSWORD` 환경 변수 설정  
   (비워두면 랜덤 비밀번호가 생성되어 deploy 로그에 출력됨)
3. `/data` 에 마운트되는 **volume** 연결
4. 앱 URL 열기 → `admin` / 비밀번호로 로그인

### 4. Admin Dashboard 설정

1. **LLM Provider** — OpenRouter 선택 후 API key와 model 입력
2. **Messaging Channel** — Telegram 체크 후 Bot Token 입력
3. **Save & Start** 클릭

> 새 Railway volume에서는 첫 부팅 시 기본 Ollama 호환 provider를 자동 시드할 수 있습니다.  
> 필요하면 `OLLAMA_HOST`, `OLLAMA_MODEL`, `OLLAMA_API_KEY`를 Railway service variables로 덮어쓸 수 있습니다.

### 5. 대화 시작

Telegram 봇에 메시지를 보내면 admin dashboard의 **Users** 섹션에 pairing 요청이 나타납니다.  
**Approve** 하면 바로 사용 가능합니다.

## 환경 변수

| 변수 | 기본값 | 설명 |
|------|--------|------|
| `PORT` | `8080` | 웹 서버 포트 (Railway가 자동 지정) |
| `ADMIN_USERNAME` | `admin` | 로그인 사용자명 |
| `ADMIN_PASSWORD` | *(자동 생성 가능)* | 로그인 비밀번호 |

나머지 설정(LLM provider, model, channel, tool)은 dashboard에서 관리합니다.

## Hermes Upstream Tracking

이 저장소는 **Hermes 전체를 포크한 저장소가 아니라 Railway wrapper**입니다.  
실제 Hermes 소스는 아래 git submodule로 고정 추적합니다.

```text
vendor/hermes-agent
```

의미:

- wrapper 전용 변경은 이 repo에 둠 (`server.py`, `templates/`, `start.sh`, Docker/Railway wiring)
- Hermes core 기능은 가능하면 upstream bump로 따라감
- 어떤 Hermes revision을 배포하는지 `git submodule status`로 바로 확인 가능

처음 clone한 뒤에는 반드시:

```bash
git submodule update --init --recursive
```

현재 upstream pin 확인 / bump helper:

```bash
scripts/update-hermes-upstream.sh
scripts/update-hermes-upstream.sh --latest-tag
```

특별한 이유가 없다면 `vendor/hermes-agent` 안을 직접 수정하지 말고,  
upstream bump 또는 upstream PR로 처리하는 것을 권장합니다.

## Bundled Default Skills

이 이미지는 [`garrytan/gstack`](https://github.com/garrytan/gstack) 스킬 번들도 기본 포함합니다.  
부팅 시 `~/.claude/skills/gstack`에 연결되고 `skills.external_dirs`에 자동 등록됩니다.

## 첫 부팅 기본 Provider 시드

새 Railway 배포에서 `/data` volume이 비어 있으면 `start.sh`가
`/data/.hermes/.env`를 시드해서 setup wizard를 끝내기 전에도 Hermes가 실행 가능하도록 만듭니다.

기본값:

- `LLM_MODEL=gemma4:26b`
- `OPENAI_API_KEY=ollama`
- `OPENAI_BASE_URL=${OLLAMA_HOST}/v1`

동작 특성:

- 기존에 `LLM_MODEL`이 있으면 덮어쓰지 않음
- `OLLAMA_HOST`, `OLLAMA_MODEL`, `OLLAMA_API_KEY`로 override 가능
- Railway에서 로컬 모델에 직접 접근할 수 없으면 public tunnel URL 필요

## 지원 Provider

OpenRouter, DeepSeek, DashScope, GLM / Z.AI, Kimi, MiniMax, HuggingFace,  
**OpenAI Codex (OAuth)**,  
**Factory Droid**,  
**Custom Endpoint** (Ollama, vLLM, llama.cpp, LM Studio 등 OpenAI-compatible API)

### OpenAI Codex OAuth 사용

1. proxied **Hermes Dashboard** 열기 (`/?force=1`)
2. **Keys** 이동
3. **OpenAI Codex (ChatGPT)** 연결
4. 다시 **Setup**으로 돌아와 **OpenAI Codex (OAuth)** 선택 후 저장

wrapper는 이후 `/data/.hermes/config.yaml`에
`model.provider: "openai-codex"`를 기록하므로 재시작 후에도 Codex 선택이 유지됩니다.

## 지원 채널

Telegram, Discord, Slack, WhatsApp, Email, Mattermost, Matrix

### Slack DMs

Slack DM이 정상적으로 Hermes로 들어오게 하려면 dashboard의 Slack 카드에서:

- **Allowed Member IDs** (`SLACK_ALLOWED_USERS`) — 본인 Slack member ID 또는 테스트용 `*`
- **Home Channel ID** (`SLACK_HOME_CHANNEL`) — 스케줄/cron 메시지용 기본 채널 (선택)

Slack 앱 요구사항:

- `im:history`, `im:read`, `im:write` scope
- `message.im` event subscription
- App Home의 **Messages Tab** 활성화

`SLACK_ALLOWED_USERS`가 비어 있으면 DM이 일반 대화 대신 unauthorized pairing처럼 처리될 수 있습니다.

## 지원 Tool Integrations

Parallel (search), Firecrawl (scraping), Tavily (search), FAL (image gen), Browserbase, GitHub, OpenAI Voice (Whisper/TTS), Honcho (memory)

## Slack MCP

Setup UI에서 Slack MCP를 켜면 아래 Hermes config를 생성합니다:

```yaml
mcp_servers:
  slack:
    url: "https://mcp.slack.com/mcp"
    auth: "oauth"
```

중요:

- Slack MCP는 일반 Slack bot channel 설정과는 별개입니다.
- 저장 후에는 `slack` 서버에 대해 Hermes MCP OAuth를 추가로 완료해야 합니다.
- Slack MCP는 현재 internal app / Slack Marketplace-published app 제한이 있습니다.
- wrapper는 `/data/.hermes/config.yaml`의 기존 `mcp_servers` 항목을 덮어쓰지 않고 보존합니다.

### Railway 친화적인 header auth 테스트

localhost callback OAuth가 Railway에서 불편한 경우를 위해 setup UI는 bearer-token 테스트 경로도 제공합니다.

1. **Tool API Keys → Slack MCP User Token**에 토큰 입력
2. 설정 저장
3. **Test header auth** 클릭

토큰이 있으면 wrapper는 아래 추가 config도 관리합니다:

```yaml
mcp_servers:
  slack_header:
    url: "https://mcp.slack.com/mcp"
    headers:
      Authorization: "Bearer ${SLACK_MCP_USER_TOKEN}"
```

이 테스트 버튼은 Slack MCP에 직접 `initialize` 요청을 보내고,
HTTP status / 에러를 setup 화면에 바로 보여줍니다.  
즉, 토큰 누락 / `401` / 성공을 shell 접속 없이 구분할 수 있습니다.

## 아키텍처

```text
Railway Container
├── Python Admin Server (Starlette + Uvicorn)
│   ├── /            — Admin dashboard (Basic Auth)
│   ├── /health      — Health check (no auth)
│   └── /api/*       — Config, status, logs, gateway, pairing
├── vendor/hermes-agent  — Pinned upstream Hermes source (git submodule)
└── hermes gateway       — Managed as async subprocess
```

admin server는 `$PORT`에서 동작하며 Hermes gateway를 child process로 관리합니다.  
Hermes 자체는 빌드 시 `vendor/hermes-agent` submodule에서 설치되고,  
upstream dashboard bundle을 미리 빌드해 wrapper proxy 뒤에서 제공합니다.

설정은:

- `/data/.hermes/.env`
- `/data/.hermes/config.yaml`

에 저장되고, gateway stdout/stderr는 ring buffer에 보관되어 Logs 패널에서 볼 수 있습니다.

## 로컬 실행

```bash
git submodule update --init --recursive
docker build -t hermes-agent .
docker run --rm -it -p 8080:8080 -e PORT=8080 -e ADMIN_PASSWORD=changeme -v hermes-data:/data hermes-agent
```

이후 `http://localhost:8080` 에 접속해 `admin / changeme`로 로그인합니다.

## HTTP를 통한 Terminal Chat

한 번 로그인해서 cookie를 저장한 뒤, wrapper의 chat endpoint로 POST하면 됩니다.

```bash
BASE="https://your-app.up.railway.app"

curl -sS -c cookies.txt -X POST "$BASE/login" \
  -d "username=admin&password=YOUR_PASSWORD" \
  -o /dev/null

curl -sS -b cookies.txt -X POST "$BASE/api/chat" \
  -H "Content-Type: application/json" \
  -d '{"message":"안녕"}'
```

응답 예시:

```json
{"ok":true,"response":"...","session_id":"20260426_123456_abcd1234"}
```

기존 session을 이어가려면 `"session_id"` 또는 `"resume"`을 함께 보내면 됩니다.  
추가로 `"skills"`, `"toolsets"`, `"model"`, `"provider"`, `"max_turns"`도 전달할 수 있습니다.

## Hermes Upstream 업데이트

현재 upstream pin 확인:

```bash
git submodule status
scripts/update-hermes-upstream.sh
```

최신 upstream `main`을 따라가려면:

```bash
scripts/update-hermes-upstream.sh --main
git add vendor/hermes-agent
python3 -m unittest -v
docker build -t hermes-agent .
```

최신 upstream release tag에 맞추고 싶다면:

```bash
scripts/update-hermes-upstream.sh --latest-tag
git add vendor/hermes-agent
python3 -m unittest -v
docker build -t hermes-agent .
```

`main`이나 latest tag 대신 특정 upstream revision을 지정하고 싶다면:

```bash
scripts/update-hermes-upstream.sh v2026.4.23
```

bump 후 최소 검증:

- setup UI가 열리는지
- `hermes gateway`가 wrapper에서 정상 기동하는지
- `hermes dashboard`가 proxy 뒤에서 정상 동작하는지
- wrapper chat endpoint가 계속 동작하는지

## 최근 변경 이력 (PR #1–#11)

- **PR #1 — Custom Endpoint provider**: Ollama, vLLM, llama.cpp, LM Studio 같은 OpenAI-compatible endpoint를 1급 provider로 지원
- **PR #2 — Factory Droid provider**: `FACTORY_API_KEY` 기반 Factory Droid setup 경로 추가
- **PR #3 — First-boot Ollama seeding**: 첫 배포 시 기본 Ollama provider 자동 시드
- **PR #4 — Slack DM config fix**: Slack DM과 scheduled message를 위해 `SLACK_ALLOWED_USERS`, `SLACK_HOME_CHANNEL` 노출
- **PR #5 — Wrapper-backed terminal chat**: `POST /api/chat`, `POST /setup/api/chat` 추가
- **PR #6 — Codex OAuth provider**: OpenAI Codex (OAuth) setup 지원 추가
- **PR #7 — Bundled gstack skills**: `garrytan/gstack` 번들을 기본 external skills 디렉터리로 포함
- **PR #8 — Current Hermes CLI compatibility**: 현재 `hermes chat -Q -q ...` 호출 형태와 wrapper 호환성 복구
- **PR #9 — Slack MCP support**: 공식 Slack MCP toggle과 기존 `mcp_servers` 보존 로직 추가
- **PR #10 — Dashboard Slack MCP discoverability**: Slack MCP helper widget 및 고대비 UI 개선
- **PR #11 — Setup-side Slack MCP header testing**: `SLACK_MCP_USER_TOKEN`, `slack_header`, one-click dashboard test 추가

## Credits

- [Hermes Agent](https://github.com/NousResearch/hermes-agent) by [Nous Research](https://nousresearch.com/)
- UI inspired by [OpenClaw](https://github.com/praveen-ks-2001/openclaw-railway) admin template
