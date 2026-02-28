# claude-terminal

Docker image: ttyd + Claude Code + Bun + Node 22 + zsh (Powerlevel10k)

## Git

- Remote: **gitlab only** (`gitlab` → `https://gitlab.ystura.com/Claude/claude-terminal.git`)
- Never push to `origin` (GitHub) — it is deprecated
- Default branch: `master`

## Stack

- Base image: `node:22-bookworm`
- Runtimes: Node 22, Bun (latest)
- Shell: zsh + Oh My Zsh + Powerlevel10k
- Web terminal: ttyd on port 7681

## Environment Variables (runtime)

- `GITLAB_SSH_PRIVATE_KEY` — SSH private key for GitLab access
- `GITLAB_SSH_PUBKEY` — baked into image
- `TTYD_USERNAME` / `TTYD_PASSWORD` — optional ttyd auth
