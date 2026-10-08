# dot-files

개인 dotfiles 설정 모음

## 구조

```
dot-files/
├── brew/       # Homebrew Brewfile
├── emacs/      # Emacs 설정
├── nvim/       # Neovim 설정
└── tmux/       # Tmux 설정
```

## 설치

```bash
git clone git@github.com:joseph-jy/dot-files.git
cd dot-files
```

### 심볼릭 링크

```bash
# Neovim
ln -s $(pwd)/nvim ~/.config/nvim

# Emacs
ln -s $(pwd)/emacs ~/.emacs.d
# emacs-plus 빌드 옵션(아이콘). 변경 후 brew reinstall --cask emacs-plus-app
mkdir -p ~/.config/emacs-plus
ln -s $(pwd)/emacs/emacs-plus/build.yml ~/.config/emacs-plus/build.yml

# Tmux
ln -s $(pwd)/tmux/tmux.conf.local ~/.tmux.conf.local
```

### Homebrew

```bash
ln -s $(pwd)/brew/Brewfile-latest ~/Brewfile
brew bundle
```
