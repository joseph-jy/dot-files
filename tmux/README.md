# tmux

tmux 셋팅은 그냥 [이게](https://github.com/gpakosz/.tmux) 제일 낫다. 이걸 사용하는 게 나을 듯
tmux.conf.local 는 Custom 하게 설정할 수 있으니 이것만 따로 보관한다.

```
$ cd
$ git clone https://github.com/gpakosz/.tmux.git /path/to/oh-my-tmux
$ ln -s "/path/to/oh-my-tmux/.tmux.conf" ~/.config/tmux/tmux.conf
$ ln -s ./tmux.conf.local ~/.config/tmux/tmux.conf.local
```
