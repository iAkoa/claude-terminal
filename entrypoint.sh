#!/bin/zsh

# ============================================
# Claude Code configuration (always regenerated with current env vars)
# ============================================

# Skip onboarding wizard
cat > ~/.claude.json <<'CONF'
{
  "numStartups": 1,
  "installMethod": "npm",
  "autoUpdates": false,
  "hasCompletedOnboarding": true,
  "lastOnboardingVersion": "2.1.63",
  "hasSeenTasksHint": true,
  "tipsHistory": {
    "new-user-warmup": 1,
    "theme-command": 1,
    "memory-command": 1
  }
}
CONF

# Auth + settings (regenerated every start to pick up env var changes)
mkdir -p ~/.claude
cat > ~/.claude/settings.json <<CONF
{
  "permissions": {
    "allow": [],
    "deny": []
  },
  "env": {
    "ANTHROPIC_BASE_URL": "${ANTHROPIC_BASE_URL:-https://api.z.ai/api/anthropic}",
    "API_TIMEOUT_MS": "${API_TIMEOUT_MS:-300000}",
    "CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC": "1",
    "DISABLE_AUTOUPDATER": "1"
  }
}
CONF

# Export as real env vars (Claude reads these before settings.json)
# Note: only ANTHROPIC_API_KEY is used — no ANTHROPIC_AUTH_TOKEN to avoid conflict
export ANTHROPIC_BASE_URL="${ANTHROPIC_BASE_URL:-https://api.z.ai/api/anthropic}"
export API_TIMEOUT_MS="${API_TIMEOUT_MS:-300000}"
export CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC=1
export DISABLE_AUTOUPDATER=1

# ============================================
# SSH setup (GitLab)
# ============================================
if [ -n "$GITLAB_SSH_PRIVATE_KEY" ]; then
    mkdir -p ~/.ssh
    echo "$GITLAB_SSH_PRIVATE_KEY" > ~/.ssh/id_ed25519
    chmod 600 ~/.ssh/id_ed25519

    if [ -n "$GITLAB_SSH_PUBKEY" ]; then
        echo "$GITLAB_SSH_PUBKEY" > ~/.ssh/id_ed25519.pub
        chmod 644 ~/.ssh/id_ed25519.pub
    fi

    ssh-keyscan -t ed25519 gitlab.ystura.com >> ~/.ssh/known_hosts 2>/dev/null

    cat > ~/.ssh/config <<EOF
Host gitlab.ystura.com
    IdentityFile ~/.ssh/id_ed25519
    StrictHostKeyChecking accept-new
EOF
    chmod 600 ~/.ssh/config
fi

# ============================================
# Launch
# ============================================
AUTH_FLAG=""
if [ -n "$TTYD_USERNAME" ] && [ -n "$TTYD_PASSWORD" ]; then
    AUTH_FLAG="-c ${TTYD_USERNAME}:${TTYD_PASSWORD}"
fi

MODEL_FLAG=""
if [ -n "$CLAUDE_MODEL" ]; then
    MODEL_FLAG="--model $CLAUDE_MODEL"
fi

exec ttyd --writable --port 7681 $AUTH_FLAG zsh -c "
while true; do
    claude --dangerously-skip-permissions $MODEL_FLAG
    echo '\nClaude exited. Restarting in 2s...'
    sleep 2
done
"
