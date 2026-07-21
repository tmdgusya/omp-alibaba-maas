#!/usr/bin/env bash
# install.sh — one-shot installer for omp-alibaba-maas
#
# Installs:
#   - bin/alibaba-maas               → ~/.local/bin/alibaba-maas
#   - omp/commands/*.md              → ~/.omp/agent/commands/
#   - omp/models.yml.example         → appended to ~/.omp/agent/models.yml if missing
#
# Does NOT install the API key. After running this, add your key to
# ~/.omp/agent/.env manually:
#
#   echo 'ALIBABA_TOKEN_PLAN_API_KEY=sk-sp-...' >> ~/.omp/agent/.env
#   chmod 600 ~/.omp/agent/.env
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# 1. CLI
mkdir -p ~/.local/bin
install -m 0755 "$SCRIPT_DIR/bin/alibaba-maas" ~/.local/bin/alibaba-maas
echo "[ok] installed ~/.local/bin/alibaba-maas"

# 2. Slash commands
mkdir -p ~/.omp/agent/commands
for f in "$SCRIPT_DIR"/omp/commands/*.md; do
  install -m 0644 "$f" ~/.omp/agent/commands/
done
echo "[ok] installed omp slash commands to ~/.omp/agent/commands/"

# 3. models.yml — only inject the provider block if it's not already there
mkdir -p ~/.omp/agent
MODELS_YML=~/.omp/agent/models.yml
touch "$MODELS_YML"
if grep -q "^  alibaba-token-plan:" "$MODELS_YML"; then
  echo "[skip] provider 'alibaba-token-plan' already in $MODELS_YML"
else
  # Ensure top-level "providers:" key exists
  if ! grep -nE "^providers:" "$MODELS_YML" >/dev/null; then
    printf '\nproviders:\n' >> "$MODELS_YML"
  fi
  # Append the provider block from the example (indent-2 content only)
  awk '
    /^providers:/ { in_providers=1; next }
    in_providers && /^  alibaba-token-plan:/ { in_block=1 }
    in_block { print }
    in_block && /^  [a-zA-Z]/ && !/^  alibaba-token-plan:/ { in_block=0 }
  ' "$SCRIPT_DIR/omp/models.yml.example" >> "$MODELS_YML"
  echo "[ok] appended 'alibaba-token-plan' provider to $MODELS_YML"
fi

# 4. Verify key file exists (don't write the key)
if [[ ! -f ~/.omp/agent/.env ]] || ! grep -q ALIBABA_TOKEN_PLAN_API_KEY ~/.omp/agent/.env 2>/dev/null; then
  echo ""
  echo "[next] add your API key:"
  echo "         echo 'ALIBABA_TOKEN_PLAN_API_KEY=sk-sp-...' >> ~/.omp/agent/.env"
  echo "         chmod 600 ~/.omp/agent/.env"
fi

echo ""
echo "[done] start a new omp session, then:"
echo "         omp models find alibaba-token-plan"
echo "         /img \"a red apple\""
