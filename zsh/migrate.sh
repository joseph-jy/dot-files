#!/usr/bin/env bash
# migrate.sh — Deploy XDG-based zsh config from dotfiles repo
# Idempotent: safe to run multiple times.
set -euo pipefail

DOTFILES_ZSH="$(cd "$(dirname "$0")" && pwd)"
TARGET="$HOME/.config/zsh"

echo "=== zsh XDG migration ==="

# 1. Backup existing ~/.zshrc (only once)
if [[ -f "$HOME/.zshrc" && ! -L "$HOME/.zshrc" && ! -f "$HOME/.zshrc.bak" ]]; then
  cp "$HOME/.zshrc" "$HOME/.zshrc.bak"
  echo "[backup] ~/.zshrc -> ~/.zshrc.bak"
fi

# 2. Symlink dotfiles/zsh -> ~/.config/zsh
mkdir -p "$HOME/.config"
if [[ -L "$TARGET" ]]; then
  echo "[skip] $TARGET already symlinked"
elif [[ -d "$TARGET" ]]; then
  echo "[warn] $TARGET exists as directory — skipping symlink (merge manually)"
else
  ln -s "$DOTFILES_ZSH" "$TARGET"
  echo "[link] $DOTFILES_ZSH -> $TARGET"
fi

# 3. Create local.zsh from example if missing
if [[ ! -f "$TARGET/local.zsh" && -f "$TARGET/local.zsh.example" ]]; then
  cp "$TARGET/local.zsh.example" "$TARGET/local.zsh"
  echo "[init] local.zsh created from example — edit with your secrets"
fi

# 4. Replace ~/.zshrc with thin loader
cat > "$HOME/.zshrc" <<'LOADER'
# Thin loader — all config lives in ~/.config/zsh/
source "${HOME}/.config/zsh/zshrc"
LOADER
echo "[write] ~/.zshrc replaced with thin loader"

echo ""
echo "Done! Restart your shell or run: source ~/.zshrc"
echo ""
echo "IMPORTANT: Edit ~/.config/zsh/local.zsh to add your secrets:"
echo "  - PLAY_PATH"
echo "  - JIRA_API_TOKEN"
