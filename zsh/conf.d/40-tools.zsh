# Tool integrations and completions

autoload -Uz compinit && compinit

# zsh-syntax-highlighting (path may differ per OS; homebrew default for macOS)
if [[ -f /opt/homebrew/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh ]]; then
  source /opt/homebrew/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
elif [[ -f /home/linuxbrew/.linuxbrew/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh ]]; then
  source /home/linuxbrew/.linuxbrew/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
elif [[ -f /usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh ]]; then
  source /usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
fi

# fzf (Ctrl-R history search, Ctrl-T, Alt-C)
# Resolve via Homebrew's fzf explicitly — brew's PATH (os/*.zsh) loads after
# this file, so a bare `fzf` here could still hit an older distro package.
if [[ -x /opt/homebrew/bin/fzf ]]; then
  source <(/opt/homebrew/bin/fzf --zsh)
elif [[ -x /home/linuxbrew/.linuxbrew/bin/fzf ]]; then
  source <(/home/linuxbrew/.linuxbrew/bin/fzf --zsh)
elif command -v fzf >/dev/null 2>&1; then
  source <(fzf --zsh)
fi

# zoxide
eval "$(zoxide init zsh)"

# bun completions
[ -s "$HOME/.bun/_bun" ] && source "$HOME/.bun/_bun"
