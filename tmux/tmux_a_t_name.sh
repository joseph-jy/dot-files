#!/bin/zsh

##
# tmux_a_t_name.sh
##
echo -n "session name : "
read session_name
tmux a -t $session_name

