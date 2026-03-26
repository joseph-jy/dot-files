# Environment variables

export EDITOR="nvim"

# PATH — common entries (deduplicated)
export PATH="$HOME/.local/bin:$PATH"

# bun
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"

# npm-global
export PATH="$HOME/.npm-global/bin:$PATH"

# pnpm
export PNPM_HOME="$HOME/.local/share/pnpm"
case ":$PATH:" in
  *":$PNPM_HOME:"*) ;;
  *) export PATH="$PNPM_HOME:$PATH" ;;
esac

# mise (polyglot version manager) — must come AFTER PATH setup
eval "$(mise activate zsh)"
