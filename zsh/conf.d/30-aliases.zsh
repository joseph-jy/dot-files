# Common aliases (cross-platform)

# Editor
alias vi="nvim"

# Shell
alias cl="clear"
alias history="history 1"
alias q='exit'

# Kubernetes
alias k="kubectl"

# tmux
alias t='tmux attach || tmux new-session'
alias ta='tmux attach -t'
alias tn='tmux new-session -s'
alias tl='tmux list-sessions'
alias tk='tmux kill-session -t'
alias td='tmux detach'

# tmuxinator
alias mux-cc='tmuxinator claude-code-workspace'
alias mux-co='tmuxinator copilot-workspace'
alias mux-ai='tmuxinator ai-agent-workspace'

# workmux
alias wm='workmux'
alias wml='workmux list'
alias wma='workmux add'
alias wmm='workmux merge'
alias wmd='workmux dashboard'

# Claude Code
alias c='claude'
alias cc='claude --continue'
alias cr='claude --resume'
alias ch='claude --chrome'
alias cus="npx ccusage"
alias cmo='claude-monitor --plan pro --view realtime'

# Git
alias gb='git branch'
alias gco='git checkout'
alias gst='git status'
alias gd='git diff'

# eza
alias ll='eza -lbh --icons'
alias lt='eza --tree --git --icons --git-ignore'
