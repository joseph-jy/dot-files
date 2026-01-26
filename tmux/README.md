# tmux

tmux 셋팅은 그냥 [이게](https://github.com/gpakosz/.tmux) 제일 낫다. 이걸 사용하는 게 나을 듯
tmux.conf.local 는 Custom 하게 설정할 수 있으니 이것만 따로 보관한다.

```
$ cd
$ git clone https://github.com/gpakosz/.tmux.git /path/to/oh-my-tmux
$ ln -s "/path/to/oh-my-tmux/.tmux.conf" ~/.config/tmux/tmux.conf
$ ln -s ./tmux.conf.local ~/.config/tmux/tmux.conf.local
```

## Git 정보 표시 (gitmux)

status right 영역에 git 정보가 나오도록 `gitmux`를 호출한다.
설치되어 있지 않으면 아무것도 표시되지 않으니 `gitmux`가 PATH에 있는지 확인한다.

```
$ which gitmux
$ gitmux "$PWD"
```

이미 `tmux.conf.local`에 아래처럼 설정되어 있다.

```
tmux_conf_theme_status_right=" ... #(gitmux \"#{pane_current_path}\") ... "
```

설정 변경 후에는 tmux를 리로드한다.

```
$ tmux source-file ~/.config/tmux/tmux.conf
```
