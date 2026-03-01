FROM node:22-bookworm

SHELL ["/bin/bash", "-c"]

# ============================================
# System packages
# ============================================
RUN apt-get update && apt-get install -y --no-install-recommends \
    zsh \
    curl \
    wget \
    git \
    jq \
    make \
    gcc \
    g++ \
    python3 \
    python3-pip \
    python3-venv \
    ripgrep \
    fd-find \
    unzip \
    openssh-client \
    ca-certificates \
    gnupg \
    postgresql-client \
    locales \
    && rm -rf /var/lib/apt/lists/* \
    && sed -i '/en_US.UTF-8/s/^# //g' /etc/locale.gen && locale-gen

ENV LANG=en_US.UTF-8
ENV LANGUAGE=en_US:en
ENV LC_ALL=en_US.UTF-8

# ============================================
# Bun
# ============================================
ENV BUN_INSTALL="/root/.bun"
ENV PATH="/root/.bun/bin:$PATH"
RUN curl -fsSL https://bun.sh/install | bash

# ============================================
# ttyd (web terminal)
# ============================================
RUN ARCH=$(uname -m) && \
    wget -qO /usr/local/bin/ttyd "https://github.com/tsl0922/ttyd/releases/download/1.7.7/ttyd.${ARCH}" && \
    chmod +x /usr/local/bin/ttyd

# ============================================
# Claude Code
# ============================================
RUN npm install -g @anthropic-ai/claude-code

# ============================================
# SSH public key
# ============================================
ENV GITLAB_SSH_PUBKEY="ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJ4jnevLnbgDjulNQfmnmc8ZDxPi2css9opevYWNnvA+ gitlab-ystura"
ENV DISABLE_AUTOUPDATER=1

# ============================================
# Non-root user
# ============================================
RUN useradd -m -s /bin/bash -G sudo claude \
    && echo "claude ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

RUN cp -r /root/.bun /home/claude/.bun \
    && chown -R claude:claude /home/claude

ENV BUN_INSTALL="/home/claude/.bun"
ENV PATH="/home/claude/.bun/bin:$PATH"

# ============================================
# Volumes & workspace
# ============================================
RUN mkdir -p /home/claude/.claude /workspace \
    && chown -R claude:claude /home/claude/.claude /workspace
VOLUME ["/home/claude/.claude", "/workspace"]
WORKDIR /workspace

# ============================================
# Entrypoint
# ============================================
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

USER claude

EXPOSE 7681

CMD ["/entrypoint.sh"]
