FROM node:20-bookworm-slim

RUN apt-get update && \
    apt-get install -y wget git curl bash && \
    rm -rf /var/lib/apt/lists/*

RUN wget -qO /usr/local/bin/ttyd https://github.com/tsl0922/ttyd/releases/download/1.7.7/ttyd.x86_64 && \
    chmod +x /usr/local/bin/ttyd

RUN npm install -g @anthropic-ai/claude-code

# Persistent directories for auth and workspace
RUN mkdir -p /root/.claude /workspace
VOLUME ["/root/.claude", "/workspace"]
WORKDIR /workspace

EXPOSE 7681

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

CMD ["/entrypoint.sh"]
