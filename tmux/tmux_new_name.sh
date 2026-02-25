#!/bin/zsh

##
# tmux_new_name.sh
##
echo -n "session name : "
read session_name
tmux new -s $session_name

