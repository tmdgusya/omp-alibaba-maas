---
description: Alibaba HappyHorse text-to-video (Token Plan)
allowed-tools: bash
---

Generate a short video with `alibaba-maas t2v` and report the result.

Run this bash command from `$HOME`:

```bash
cd ~ && alibaba-maas t2v $ARGUMENTS
```

`$ARGUMENTS` is the user's raw text after `/video`. It must include at least a prompt; optional flags pass through: `--duration 3..15`, `--resolution 720P|1080P`, `--ratio 16:9`, `--watermark`, `--seed N`, `--fire-and-forget` (returns task_id immediately), `--interval SEC`, `--max-wait SEC`, `--no-download`.

Default is 1080P with no watermark. The call polls until the task finishes (typically 60–180s for short clips).

Examples:
- `/video "slow zoom on a red apple, soft light" --duration 5 --ratio 16:9`
- `/video "cream absorbing into skin, macro" --duration 3 --resolution 720P --fire-and-forget` (then use `alibaba-maas poll <task_id>`)

After the command finishes:
1. Report the OSS video URL (24h-valid) and the local `~/maas-output/*.mp4` path.
2. If `--fire-and-forget` was used, just report the task_id and tell the user to run `alibaba-maas poll <task_id>` later.
3. Surface any error verbatim. Do NOT call any other video API.
