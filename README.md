# Alibaba Token Plan × omp

A self-contained integration kit for using an **Alibaba Cloud Bailian (Model Studio) Token Plan** subscription from inside [omp](https://github.com/can1357/oh-my-pi) (or any shell).

You get three things:

1. **Chat models provider** — Qwen3 / GLM-5.2 / DeepSeek V4 exposed as an OpenAI-compatible omp provider. Selectable in `/model`.
2. **Image/Video CLI** — `alibaba-maas` wraps wan2.7-image (text-to-image, image editing) and HappyHorse 1.1 (t2v / i2v / r2v) with task polling and auto-download.
3. **omp slash commands** — `/img`, `/video`, `/video-i2v` for in-session generation without leaving the chat.

```
   omp session  ───────────────┐
   │ /model qwen3.7-max         │  ← chat (provider in models.yml)
   │ /img "red apple" --size 2K │  ← image (slash cmd → alibaba-maas CLI)
   │ /video "zoom-in" --duration 5
   └────────────────────────────┘
                 │
                 ▼
   Alibaba Bailian Token Plan
   token-plan.ap-southeast-1.maas.aliyuncs.com
   ├── /compatible-mode/v1/chat/completions    (chat)
   ├── /api/v1/services/aigc/multimodal-generation/generation  (image sync)
   └── /api/v1/services/aigc/video-generation/video-synthesis  (video async)
```

---

## Prerequisites

- An omp install (`omp --version` works).
- An **Alibaba Cloud Bailian Token Plan** subscription in the Singapore region (`ap-southeast-1`). Other regions work if you adjust the host; this kit defaults to Singapore because Token Plan is currently offered there.
- The Token Plan API key. It starts with `sk-sp-` and is region-locked to the Token Plan workspace host.
- Python 3.10+ (the CLI uses stdlib only — no pip install).

The Token Plan key is **not** the same as a regular Bailian API key. The regular key returns `401 InvalidApiKey` on the Token Plan host, and vice versa.

---

## Setup

### 1. Install the CLI

```bash
mkdir -p ~/.local/bin
curl -fsSL https://raw.githubusercontent.com/tmdgusya/omp-alibaba-maas/master/bin/alibaba-maas \
  -o ~/.local/bin/alibaba-maas
chmod +x ~/.local/bin/alibaba-maas
```

Verify `~/.local/bin` is on your `PATH` (it usually is on macOS/Linux):

```bash
which alibaba-maas
# /Users/you/.local/bin/alibaba-maas
```

### 2. Store the API key

Create `~/.omp/agent/.env` (loaded automatically by omp at startup):

```bash
cat >> ~/.omp/agent/.env <<'EOF'
ALIBABA_TOKEN_PLAN_API_KEY=sk-sp-...your-key...
EOF
chmod 600 ~/.omp/agent/.env
```

This file is read by both omp (for the chat provider) and the CLI (for image/video). You only need to put the key in one place.

### 3. Register the chat provider in omp

Append to `~/.omp/agent/models.yml` (create if missing). See [`omp/models.yml.example`](./omp/models.yml.example) for the full file:

```yaml
providers:
  alibaba-token-plan:
    baseUrl: https://token-plan.ap-southeast-1.maas.aliyuncs.com/compatible-mode/v1
    api: openai-completions
    apiKey: ALIBABA_TOKEN_PLAN_API_KEY   # env-var name; resolved from ~/.omp/agent/.env
    authHeader: true
    models:
      - id: qwen3.8-max-preview
        name: Qwen3.8 Max (Preview)
        reasoning: true
        input: [text]
        contextWindow: 1000000
        maxTokens: 16384
      # ... (qwen3.7-max, qwen3.7-plus, qwen3.6-flash, glm-5.2, deepseek-v4-pro)
```

Verify:

```bash
omp models find alibaba-token-plan
```

You should see six chat models. Inside an omp session, `/model` now lists them.

### 4. (Optional) Make it the default

Edit `~/.omp/agent/config.yml`:

```yaml
modelRoles:
  default: alibaba-token-plan/qwen3.8-max-preview:max
```

`omp config get modelRoles` shows the resolved value.

### 5. Install the slash commands

```bash
mkdir -p ~/.omp/agent/commands
cp omp/commands/*.md ~/.omp/agent/commands/
```

Start a new omp session. You now have:

```
/img <prompt> [--size 1K|2K|4K] [--model wan2.7-image|wan2.7-image-pro] ...
/video <prompt> [--duration 3..15] [--resolution 720P|1080P] [--ratio 16:9] ...
/video-i2v <frame_url> <prompt> [--duration 3..15] ...
```

Outputs land in `~/maas-output/`.

### One-shot install

```bash
curl -fsSL https://raw.githubusercontent.com/tmdgusya/omp-alibaba-maas/master/install.sh | bash
```

Then add your API key to `~/.omp/agent/.env` manually (the installer will not prompt for it).

---

## Why image/video aren't in `models.yml`

omp's `models.yml` provider model assumes one provider = one wire API = one endpoint. Bailian's image and video APIs don't fit that:

- wan2.7-image is **synchronous** at `/api/v1/services/aigc/multimodal-generation/generation` and returns a final image URL inline (5–15 s).
- HappyHorse video is **asynchronous** at `/api/v1/services/aigc/video-generation/video-synthesis`, returns a `task_id`, and must be polled at `/api/v1/tasks/{task_id}` (60–180 s).
- Both require the `Authorization: Bearer` header; video also requires `X-DashScope-Async: enable`.

There is no OpenAI-compatible surface for these on the Token Plan host. `GET /compatible-mode/v1/images/generations` and `/videos/generations` return `404`. So the CLI talks to the Bailian native API directly.

---

## API surface reference

All paths are relative to `https://token-plan.ap-southeast-1.maas.aliyuncs.com`.

| Purpose | Method | Path | Headers | Mode |
|---|---|---|---|---|
| List models | `GET` | `/compatible-mode/v1/models` | `Authorization` | sync |
| Chat | `POST` | `/compatible-mode/v1/chat/completions` | `Authorization` | sync |
| Image (text-to-image, editing) | `POST` | `/api/v1/services/aigc/multimodal-generation/generation` | `Authorization` | sync |
| Image (async alternative) | `POST` | `/api/v1/services/aigc/image-generation/generation` | `Authorization`, `X-DashScope-Async: enable` | async |
| Video (t2v / i2v / r2v) | `POST` | `/api/v1/services/aigc/video-generation/video-synthesis` | `Authorization`, `X-DashScope-Async: enable` | async |
| Poll any async task | `GET` | `/api/v1/tasks/{task_id}` | `Authorization` | sync |

Result URLs (OSS) are valid for **24 hours**. Download immediately.

---

## Models

Visible at `GET /compatible-mode/v1/models`:

| Model | Family | Chat? | In this kit? |
|---|---|---|---|
| `qwen3.8-max-preview` | Qwen | ✓ | provider |
| `qwen3.7-max` | Qwen | ✓ | provider |
| `qwen3.7-plus` | Qwen | ✓ | provider |
| `qwen3.6-flash` | Qwen | ✓ | provider |
| `glm-5.2` | Zhipu | ✓ | provider |
| `deepseek-v4-pro` | DeepSeek | ✓ | provider |
| `wan2.7-image` | Wan | ✗ (image) | CLI `/img` |
| `wan2.7-image-pro` | Wan | ✗ (image, 4K) | CLI `/img --model wan2.7-image-pro` |
| `happyhorse-1.1-t2v` | HappyHorse | ✗ (video) | CLI `/video` |
| `happyhorse-1.1-i2v` | HappyHorse | ✗ (video) | CLI `/video-i2v` |
| `happyhorse-1.1-r2v` | HappyHorse | ✗ (video) | CLI `alibaba-maas r2v` |

Reasoning models emit `reasoning_content`; omp's `openai-completions` transport auto-detects this.

---

## CLI reference

```
alibaba-maas image <prompt> [--model wan2.7-image|wan2.7-image-pro]
                            [--size 1K|2K|4K] [--n N] [--no-thinking]
                            [--image URL ...]   # editing
                            [--sequential]      # group/sequence mode
                            [--watermark] [--seed N]
alibaba-maas t2v   <prompt> [--duration 3..15] [--resolution 720P|1080P]
                            [--ratio 16:9] [--watermark] [--seed N]
                            [--fire-and-forget] [--interval SEC] [--max-wait SEC]
alibaba-maas i2v   <frame_url> <prompt> [--duration 3..15] [--resolution ...]
alibaba-maas r2v   <prompt> --reference URL [URL ...]
alibaba-maas poll  <task_id> [--interval SEC] [--max-watch SEC]
```

All subcommands accept `--api-key <key>` (overrides env/.env), `--out PATH`, `--no-download`.

Key resolution order: `--api-key` flag → `$ALIBABA_TOKEN_PLAN_API_KEY` → `~/.omp/agent/.env`.

---

## Troubleshooting

**`InvalidApiKey` on `dashscope.aliyuncs.com`** — Token Plan keys are region-locked to `token-plan.ap-southeast-1.maas.aliyuncs.com`. Don't use the international dashscope host with a Token Plan key.

**`AccessDenied: current user api does not support asynchronous calls`** on image generation — you used the async path with `X-DashScope-Async: enable`. For wan2.7-image, the sync path (`/multimodal-generation/generation`, no async header) is the default and recommended. The CLI handles this for you.

**`AccessDenied: current user api does not support synchronous calls`** on video — opposite case. Video requires `X-DashScope-Async: enable`. The CLI sets this automatically.

**`url error, please check url`** — wrong endpoint path. Each model family has its own. See the [API surface table](#api-surface-reference).

**omp doesn't see the new provider** — `omp models refresh` rebuilds the catalog from `models.yml`. Confirm YAML is valid: `python3 -c "import yaml; yaml.safe_load(open('~/.omp/agent/models.yml'.replace('~', __import__('os').path.expanduser('~'))))"`.

**Slash commands not visible** — they're loaded at session start. Open a new omp session, or run `/move .` to refresh capability discovery in the current one.

**Result URLs expire in 24h** — OSS signed URLs are short-lived. The CLI auto-downloads to `~/maas-output/`; if you pass `--no-download`, save the URL yourself immediately.

---

## Files

```
.
├── README.md                  # this guide
├── LICENSE                    # MIT
├── install.sh                 # one-shot installer
├── bin/
│   └── alibaba-maas           # CLI (stdlib Python, no deps)
├── omp/
│   ├── commands/
│   │   ├── img.md             # /img slash command
│   │   ├── video.md           # /video slash command
│   │   └── video-i2v.md       # /video-i2v slash command
│   ├── models.yml.example     # chat provider snippet
│   └── env.example            # .env template
└── docs/
    └── endpoints.md           # API surface reference (long form)
```

---

## License

MIT. See [`LICENSE`](./LICENSE).

`alibaba-maas`, `wan2.7`, `happyhorse`, `Qwen`, `GLM`, `DeepSeek`, and `Bailian` are Alibaba Cloud / Zhipu AI / DeepSeek trademarks; this project is independent and not affiliated with or endorsed by those companies.
