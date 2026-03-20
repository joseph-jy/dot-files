# Environment variables

export EDITOR="nvim"

# PATH — common entries (deduplicated)
export PATH="$HOME/bin:$HOME/.local/bin:$PATH"

# bun
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"

# mise (polyglot version manager) — must come AFTER PATH setup
eval "$(mise activate zsh)"
