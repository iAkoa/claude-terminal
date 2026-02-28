FROM node:22-bookworm

SHELL ["/bin/bash", "-c"]

# ============================================
# System packages - comprehensive dev toolkit
# ============================================
RUN apt-get update && apt-get install -y --no-install-recommends \
    # Shell & terminal
    zsh \
    tmux \
    less \
    # Network & HTTP
    curl \
    wget \
    net-tools \
    dnsutils \
    iputils-ping \
    socat \
    netcat-openbsd \
    # Dev essentials
    git \
    jq \
    yq \
    make \
    cmake \
    gcc \
    g++ \
    neovim \
    # Python
    python3 \
    python3-pip \
    python3-venv \
    # Search & file tools
    ripgrep \
    fd-find \
    fzf \
    tree \
    unzip \
    zip \
    xz-utils \
    # System monitoring
    htop \
    procps \
    strace \
    # SSH & security
    openssh-client \
    ca-certificates \
    gnupg \
    # Database clients
    sqlite3 \
    postgresql-client \
    # Locale
    locales \
    && rm -rf /var/lib/apt/lists/* \
    && sed -i '/en_US.UTF-8/s/^# //g' /etc/locale.gen && locale-gen \
    # Verify critical packages
    && jq --version && git --version && python3 --version && curl --version | head -1

ENV LANG=en_US.UTF-8
ENV LANGUAGE=en_US:en
ENV LC_ALL=en_US.UTF-8

# ============================================
# Bun (latest) - direct binary install
# ============================================
ENV BUN_INSTALL="/root/.bun"
ENV PATH="/root/.bun/bin:$PATH"
RUN curl -fsSL https://bun.sh/install | bash \
    && bun --version

# ============================================
# ttyd (web terminal) - multi-arch
# ============================================
RUN ARCH=$(uname -m) && \
    wget -qO /usr/local/bin/ttyd "https://github.com/tsl0922/ttyd/releases/download/1.7.7/ttyd.${ARCH}" && \
    chmod +x /usr/local/bin/ttyd \
    && ttyd --version

# ============================================
# eza (better ls) - multi-arch
# ============================================
RUN ARCH=$(uname -m) && \
    wget -qO /tmp/eza.tar.gz "https://github.com/eza-community/eza/releases/latest/download/eza_${ARCH}-unknown-linux-gnu.tar.gz" && \
    tar xzf /tmp/eza.tar.gz -C /usr/local/bin && \
    rm /tmp/eza.tar.gz \
    && eza --version

# ============================================
# zoxide (better cd)
# ============================================
RUN curl -sS https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | bash \
    && /root/.local/bin/zoxide --version
ENV PATH="/root/.local/bin:$PATH"

# ============================================
# Claude Code (latest)
# ============================================
RUN npm install -g @anthropic-ai/claude-code \
    && claude --version

# ============================================
# Oh My Zsh + plugins + Powerlevel10k
# ============================================
RUN sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended \
    && git clone https://github.com/zsh-users/zsh-autosuggestions /root/.oh-my-zsh/custom/plugins/zsh-autosuggestions \
    && git clone https://github.com/zsh-users/zsh-syntax-highlighting /root/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting \
    && git clone --depth=1 https://github.com/romkatv/powerlevel10k.git /root/.oh-my-zsh/custom/themes/powerlevel10k

# ============================================
# SSH public key (env var)
# ============================================
ENV GITLAB_SSH_PUBKEY="ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJ4jnevLnbgDjulNQfmnmc8ZDxPi2css9opevYWNnvA+ gitlab-ystura"

# ============================================
# Volumes & workspace
# ============================================
RUN mkdir -p /root/.claude /workspace
VOLUME ["/root/.claude", "/workspace"]
WORKDIR /workspace

# ============================================
# Config files
# ============================================
COPY .zshrc /root/.zshrc
COPY .p10k.zsh /root/.p10k.zsh
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# Default shell = zsh
RUN chsh -s /bin/zsh

EXPOSE 7681

CMD ["/entrypoint.sh"]
