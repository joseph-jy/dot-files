# Emacs Maintenance Rules

- When changing `emacs/init.el` in a way that affects packages, keybindings, prefix maps, debug templates, LSP commands, Git/Magit flows, Treemacs flows, or other shortcut-driven workflows, review and update `emacs/cheatsheet.html` in the same change.
- When changing the "먼저 익힐 키" section in `emacs/README.md`, keep `emacs/cheatsheet.html` in sync.
- Do not update `emacs/reference-card.html` for personal Emacs configuration changes unless the generic GNU Emacs default reference itself is changing.
