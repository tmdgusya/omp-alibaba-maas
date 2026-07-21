---
description: Alibaba HappyHorse image-to-video (Token Plan)
allowed-tools: bash
---

Generate a video from a first-frame image with `alibaba-maas i2v` and report the result.

Run this bash command from `$HOME`:

```bash
cd ~ && alibaba-maas i2v $ARGUMENTS
```

`$ARGUMENTS` is the user's raw text after `/video-i2v`. The first positional must be an HTTPS URL to the first-frame image (JPEG/JPG/PNG/WEBP, both dims ≥ 300px, aspect 1:2.5–2.5:1, ≤ 20MB). The second positional is the prompt. Optional flags: `--duration 3..15`, `--resolution 720P|1080P`, `--watermark`, `--seed N`, `--fire-and-forget`, `--no-download`.

Output aspect ratio automatically follows the input first-frame image; do not pass `--ratio`.

Examples:
- `/video-i2v https://cdn.example.com/start.png "slow camera push-in, soft light"`
- `/video-i2v https://cdn.example.com/keyframe.png "formula absorbing into skin" --duration 5 --resolution 1080P`

After the command finishes:
1. Report the OSS video URL (24h-valid) and the local `~/maas-output/*.mp4` path.
2. If `--fire-and-forget` was used, report the task_id and tell the user to run `alibaba-maas poll <task_id>` later.
3. Surface any error verbatim. Do NOT call any other video API.
