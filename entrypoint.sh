#!/bin/zsh

# Setup SSH from environment variable (private key)
# Usage: pass GITLAB_SSH_PRIVATE_KEY at docker run time
if [ -n "$GITLAB_SSH_PRIVATE_KEY" ]; then
    mkdir -p /root/.ssh
    echo "$GITLAB_SSH_PRIVATE_KEY" > /root/.ssh/id_ed25519
    chmod 600 /root/.ssh/id_ed25519

    if [ -n "$GITLAB_SSH_PUBKEY" ]; then
        echo "$GITLAB_SSH_PUBKEY" > /root/.ssh/id_ed25519.pub
        chmod 644 /root/.ssh/id_ed25519.pub
    fi

    # Auto-accept GitLab host key
    ssh-keyscan -t ed25519 gitlab.ystura.com >> /root/.ssh/known_hosts 2>/dev/null

    cat > /root/.ssh/config <<EOF
Host gitlab.ystura.com
    IdentityFile /root/.ssh/id_ed25519
    StrictHostKeyChecking accept-new
EOF
    chmod 600 /root/.ssh/config
fi

# ttyd auth (optional)
AUTH_FLAG=""
if [ -n "$TTYD_USERNAME" ] && [ -n "$TTYD_PASSWORD" ]; then
    AUTH_FLAG="-c ${TTYD_USERNAME}:${TTYD_PASSWORD}"
fi

exec ttyd --writable --port 7681 $AUTH_FLAG zsh
