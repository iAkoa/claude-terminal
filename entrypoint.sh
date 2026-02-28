#!/bin/zsh

# Setup SSH from environment variable (private key)
# Usage: pass GITLAB_SSH_PRIVATE_KEY at docker run time
if [ -n "$GITLAB_SSH_PRIVATE_KEY" ]; then
    mkdir -p ~/.ssh
    echo "$GITLAB_SSH_PRIVATE_KEY" > ~/.ssh/id_ed25519
    chmod 600 ~/.ssh/id_ed25519

    if [ -n "$GITLAB_SSH_PUBKEY" ]; then
        echo "$GITLAB_SSH_PUBKEY" > ~/.ssh/id_ed25519.pub
        chmod 644 ~/.ssh/id_ed25519.pub
    fi

    # Auto-accept GitLab host key
    ssh-keyscan -t ed25519 gitlab.ystura.com >> ~/.ssh/known_hosts 2>/dev/null

    cat > ~/.ssh/config <<EOF
Host gitlab.ystura.com
    IdentityFile ~/.ssh/id_ed25519
    StrictHostKeyChecking accept-new
EOF
    chmod 600 ~/.ssh/config
fi

# ttyd auth (optional)
AUTH_FLAG=""
if [ -n "$TTYD_USERNAME" ] && [ -n "$TTYD_PASSWORD" ]; then
    AUTH_FLAG="-c ${TTYD_USERNAME}:${TTYD_PASSWORD}"
fi

# Lock into Claude Code - auto-restart on exit
exec ttyd --writable --port 7681 $AUTH_FLAG zsh -c '
while true; do
    claude --dangerously-skip-permissions
    echo "\nClaude exited. Restarting in 2s..."
    sleep 2
done
'
