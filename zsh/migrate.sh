#!/usr/bin/env bash
# migrate.sh — Deploy XDG-based zsh + git config from dotfiles repo
# Idempotent: safe to run multiple times.
set -euo pipefail

DOTFILES_ZSH="$(cd "$(dirname "$0")" && pwd)"
DOTFILES_ROOT="$(cd "$DOTFILES_ZSH/.." && pwd)"
TARGET="$HOME/.config/zsh"

echo "=== dotfiles migration ==="

# ── Environment selection ────────────────────────────────────
echo ""
echo "Select environment:"
echo "  1) personal-mac"
echo "  2) personal-ubuntu"
echo "  3) work-mac"
read -rp "Choice [1-3]: " env_choice

case "$env_choice" in
  1) ENV_NAME="personal-mac" ;;
  2) ENV_NAME="personal-ubuntu" ;;
  3) ENV_NAME="work-mac" ;;
  *) echo "[error] Invalid choice"; exit 1 ;;
esac
echo "[env] Selected: $ENV_NAME"

# ── ZSH config ───────────────────────────────────────────────

echo ""
echo "--- zsh ---"

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

# 3. Create local.zsh from environment example if missing
if [[ ! -f "$TARGET/local.zsh" ]]; then
  EXAMPLE="$DOTFILES_ZSH/examples/${ENV_NAME}.zsh"
  if [[ -f "$EXAMPLE" ]]; then
    cp "$EXAMPLE" "$TARGET/local.zsh"
    echo "[init] local.zsh created from examples/${ENV_NAME}.zsh — edit with your values"
  elif [[ -f "$TARGET/local.zsh.example" ]]; then
    cp "$TARGET/local.zsh.example" "$TARGET/local.zsh"
    echo "[init] local.zsh created from example — edit with your values"
  fi
else
  echo "[skip] local.zsh already exists"
fi

# 4. Replace ~/.zshrc with thin loader
cat > "$HOME/.zshrc" <<'LOADER'
# Thin loader — all config lives in ~/.config/zsh/
source "${HOME}/.config/zsh/zshrc"
LOADER
echo "[write] ~/.zshrc replaced with thin loader"

# ── Git config ────────────────────────────────────────────────

echo ""
echo "--- git ---"

# 5. Symlink ~/.gitconfig -> dot-files/git/gitconfig (base)
GITCONFIG_SRC="$DOTFILES_ROOT/git/gitconfig"
if [[ -L "$HOME/.gitconfig" ]]; then
  rm "$HOME/.gitconfig"
fi
ln -sf "$GITCONFIG_SRC" "$HOME/.gitconfig"
echo "[link] ~/.gitconfig -> $GITCONFIG_SRC"

# 6. Setup ~/.config/dotfiles/git/ for includeIf targets
DOTFILES_GIT_DIR="$HOME/.config/dotfiles/git"
mkdir -p "$DOTFILES_GIT_DIR"

# Personal identity (always from this repo)
ln -sf "$DOTFILES_ROOT/git/gitconfig.personal" "$DOTFILES_GIT_DIR/gitconfig.personal"
echo "[link] $DOTFILES_GIT_DIR/gitconfig.personal -> $DOTFILES_ROOT/git/gitconfig.personal"

# Work identity (from company repo, if present)
WORK_GITCONFIG="$HOME/Documents/github.daumkakao.com/joseph-jyoon/dotfiles/git/gitconfig"
if [[ -f "$WORK_GITCONFIG" ]]; then
  ln -sf "$WORK_GITCONFIG" "$DOTFILES_GIT_DIR/gitconfig.work"
  echo "[link] $DOTFILES_GIT_DIR/gitconfig.work -> $WORK_GITCONFIG"
else
  echo "[skip] Company gitconfig not found at $WORK_GITCONFIG — work identity not linked"
fi

# ── Done ──────────────────────────────────────────────────────

echo ""
echo "Done! Restart your shell or run: source ~/.zshrc"
echo ""
echo "Verify git identity:"
echo "  git -C ~/Documents/github.com/any-repo config user.email"
echo "  git -C ~/Documents/github.daumkakao.com/any-repo config user.email"
