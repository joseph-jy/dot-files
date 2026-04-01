# Environment variables

export EDITOR="nvim"

# PATH — common entries (deduplicated)
export PATH="$HOME/.local/bin:$PATH"

# play-1.40
export PLAY_1_4_0_PATH="/Users/joseph-jyoon/Documents/github.daumkakao.com/kakao-gift/gift-play-1.4.0"
export PATH="$PLAY_1_4_0_PATH:$PATH"

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
