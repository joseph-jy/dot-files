#!/bin/zsh

##
# tmux_kill-session.sh
##
echo -n "sesson name : "
read session_name
tmux kill-session -t $session_name

