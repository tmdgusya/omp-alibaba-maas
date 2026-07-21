---
description: Alibaba wan2.7 text-to-image (Token Plan)
allowed-tools: bash
---

Generate an image with `alibaba-maas image` and report the result.

Run this bash command from `$HOME` (so outputs land in `~/maas-output/`):

```bash
cd ~ && alibaba-maas image $ARGUMENTS
```

`$ARGUMENTS` is the user's raw text after `/img`. It must include at least a prompt; optional flags pass through to the CLI: `--model wan2.7-image|wan2.7-image-pro`, `--size 1K|2K|4K`, `--n N`, `--image URL` (editing), `--no-thinking`, `--sequential`, `--watermark`, `--seed N`.

Examples the user might have typed:
- `/img "a red apple on a white table"`
- `/img "product shot, premium bottle" --size 2K --model wan2.7-image-pro`
- `/img "put the graffiti on the car" --image https://example.com/car.webp --image https://example.com/paint.webp`

After the command finishes:
1. Report the OSS URL line(s) on stdout (those are the 24h-valid image URLs).
2. Report the local saved path(s) under `~/maas-output/`.
3. Do NOT re-host or re-upload anything. Do NOT call any other image API. If the command fails, surface the error verbatim.
