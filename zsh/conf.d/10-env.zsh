# Environment variables

export EDITOR="nvim"

# mise (polyglot version manager)
eval "$(mise activate zsh)"

# PATH — common entries (deduplicated)
export PATH="$HOME/bin:$HOME/.local/bin:$PATH"

# bun
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"
