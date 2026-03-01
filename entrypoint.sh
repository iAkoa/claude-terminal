#!/bin/zsh

# ============================================
# Claude Code configuration
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

# Export env vars (Claude reads these at startup)
export ANTHROPIC_BASE_URL="${ANTHROPIC_BASE_URL:-https://api.z.ai/api/anthropic}"
export API_TIMEOUT_MS="${API_TIMEOUT_MS:-300000}"
export CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC=1
export DISABLE_AUTOUPDATER=1

# ============================================
# Claude config repo (skills, agents, hooks, scripts, CLAUDE.md)
# ============================================
CONFIG_REPO="https://gitlab.ystura.com/Claude/claude-config.git"

if [ -d ~/.claude/.git ]; then
    git -C ~/.claude pull --ff-only --quiet 2>/dev/null
else
    rm -rf ~/.claude
    git clone --quiet "$CONFIG_REPO" ~/.claude
fi

# Install script dependencies (command-validator, statusline, etc.)
if [ -f ~/.claude/scripts/package.json ]; then
    (cd ~/.claude/scripts && bun install --frozen-lockfile --silent 2>/dev/null)
fi

# ============================================
# Override settings.json for container environment
# (repo version has macOS paths that don't work here)
# ============================================
CLAUDE_HOME="$HOME/.claude"
cat > "$CLAUDE_HOME/settings.json" <<CONF
{
  "permissions": {
    "allow": [],
    "deny": []
  },
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Bash",
        "hooks": [
          {
            "type": "command",
            "command": "bun $CLAUDE_HOME/scripts/command-validator/src/cli.ts"
          }
        ]
      }
    ],
    "PostToolUse": [
      {
        "matcher": "Write|Edit",
        "hooks": [
          {
            "type": "command",
            "command": "bun $CLAUDE_HOME/scripts/code-quality/src/cli.ts"
          }
        ]
      }
    ],
    "Stop": [
      {
        "matcher": "",
        "hooks": [
          {
            "type": "command",
            "command": "git diff --name-only 2>/dev/null | grep -qE '\\\\.(ts|tsx|js|jsx|py)\$' && echo '[Stop check] Unstaged code changes detected — verify typecheck/lint/tests were run.' || true",
            "timeout": 10
          }
        ]
      }
    ]
  },
  "skipDangerousModePermissionPrompt": true,
  "env": {
    "ANTHROPIC_BASE_URL": "${ANTHROPIC_BASE_URL:-https://api.z.ai/api/anthropic}",
    "API_TIMEOUT_MS": "${API_TIMEOUT_MS:-300000}",
    "CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC": "1",
    "DISABLE_AUTOUPDATER": "1",
    "CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS": "1"
  }
}
CONF

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

exec ttyd --writable --port 7681 $AUTH_FLAG zsh -c '
while true; do
    # Sync config before each Claude session (picks up latest skills/agents)
    git -C ~/.claude pull --ff-only --quiet 2>/dev/null
    claude --dangerously-skip-permissions
    echo "\nClaude exited. Restarting in 2s..."
    sleep 2
done
'
