# Bailian Token Plan — API surface reference

All paths are relative to **`https://token-plan.ap-southeast-1.maas.aliyuncs.com`** (Singapore Token Plan workspace host). Replace the host for other regions; the API key is region-locked.

## Authentication

Every request must carry:

```
Authorization: Bearer <ALIBABA_TOKEN_PLAN_API_KEY>
Content-Type: application/json
```

For async endpoints, also:

```
X-DashScope-Async: enable
```

## Endpoints

### Chat (OpenAI-compatible)

| Method | Path | Mode |
|---|---|---|
| `GET` | `/compatible-mode/v1/models` | sync |
| `POST` | `/compatible-mode/v1/chat/completions` | sync |

Standard OpenAI request/response shape. Reasoning models emit `message.reasoning_content`.

### Image — wan2.7-image / wan2.7-image-pro

**Sync (recommended)** — `POST /api/v1/services/aigc/multimodal-generation/generation`

```json
{
  "model": "wan2.7-image",
  "input": {
    "messages": [
      { "role": "user", "content": [ {"text": "a red apple on a white table"} ] }
    ]
  },
  "parameters": {
    "size": "1K",
    "n": 1,
    "watermark": false,
    "thinking_mode": true
  }
}
```

For editing, add `{"image": "<URL>"}` entries before the `text` in `content`.

Response returns the image URL inline in `output.choices[].message.content[].image`. Takes 5–15 seconds.

**Async** — `POST /api/v1/services/aigc/image-generation/generation` with `X-DashScope-Async: enable` returns `output.task_id`; poll `GET /api/v1/tasks/{task_id}`. Use this only if you need to decouple submit from result (e.g. batch generation).

### Video — happyhorse-1.1-t2v / i2v / r2v

**All video calls are async.** `POST /api/v1/services/aigc/video-generation/video-synthesis` with `X-DashScope-Async: enable`.

**t2v:**
```json
{
  "model": "happyhorse-1.1-t2v",
  "input": { "prompt": "a cat walking on a beach" },
  "parameters": { "resolution": "1080P", "duration": 5 }
}
```

**i2v** (first-frame):
```json
{
  "model": "happyhorse-1.1-i2v",
  "input": {
    "prompt": "the apple slowly rotates",
    "media": [ { "type": "first_frame", "url": "https://cdn/.../start.png" } ]
  },
  "parameters": { "resolution": "1080P", "duration": 5 }
}
```

**r2v** (reference, for character consistency):
```json
{
  "model": "happyhorse-1.1-r2v",
  "input": {
    "prompt": "the main character walks through a market",
    "media": [ { "type": "reference", "url": "https://cdn/.../char1.png" } ]
  },
  "parameters": { "resolution": "1080P", "duration": 5 }
}
```

Response returns `output.task_id` with `task_status: PENDING`. Takes 60–180 seconds depending on duration and resolution.

### Poll any async task

`GET /api/v1/tasks/{task_id}`

```json
{
  "output": {
    "task_id": "...",
    "task_status": "SUCCEEDED",
    "video_url": "https://dashscope-xxx.oss-xxx.aliyuncs.com/...mp4?..."
  },
  "usage": { "duration": 5, "SR": 1080 }
}
```

`task_status` values: `PENDING`, `RUNNING`, `SUCCEEDED`, `FAILED`, `CANCELED`, `UNKNOWN`. Poll interval: ~15s. Result URL valid **24 hours**.

## Constraints

| Input | Limit |
|---|---|
| Image upload | JPEG / JPG / PNG / WEBP / BMP; dims ≥ 240 px; aspect 1:8–8:1; ≤ 20 MB |
| First-frame (i2v) | JPEG / PNG / WEBP; both dims ≥ 300 px; aspect 1:2.5–2.5:1; ≤ 20 MB |
| Text prompt | ≤ 5000 non-CJK chars (≤ 2500 CJK) |
| Video duration | 3–15 s integer |
| Video resolution | `720P`, `1080P` (default) |
| Text-to-video ratio | configurable (e.g. `16:9`); image-to-video ratio follows input |
| Watermark | Default off for image, **default ON** ("Happy Horse") for video — pass `watermark: false` to disable |

## Common errors

| Code | Cause | Fix |
|---|---|---|
| `InvalidApiKey` on a different host | Token Plan keys are region-locked | Use `token-plan.ap-southeast-1.maas.aliyuncs.com` |
| `AccessDenied: does not support asynchronous calls` | Used async header on sync-only image endpoint | Remove `X-DashScope-Async` for sync image gen |
| `AccessDenied: does not support synchronous calls` | Used sync mode on async endpoint (video) | Add `X-DashScope-Async: enable` |
| `InvalidParameter: url error` | Wrong path for the model family | Each family has its own endpoint — see above |

## References

- wan2.7-image generation/editing — https://help.aliyun.com/zh/model-studio/wan-image-generation-and-editing-api-reference
- HappyHorse image-to-video — https://help.aliyun.com/zh/model-studio/happyhorse-image-to-video-api-reference
- DashScope API overview — https://www.alibabacloud.com/help/en/model-studio/qwen-api-via-dashscope
- Error codes — https://www.alibabacloud.com/help/en/model-studio/error-code
