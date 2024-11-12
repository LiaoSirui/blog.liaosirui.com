## Tmux 简介

Tmux 是一个终端复用器（terminal multiplexer）

<img src="./.assets/tmux终端复用器/bg2019102005.png" alt="img" style="zoom:25%;" />

类似的终端复用器还有 GNU Screen。Tmux 与它功能相似，但是更易用，也更强大

Tmux 一般需要自己安装

```bash
# Ubuntu 或 Debian
sudo apt install tmux
 
# CentOS 或 Fedora
sudo dnf install tmux
```

## Tmux 基础操作

- 新建会话

```bash
tmux new -s <session-name>
```

上面命令新建一个指定名称的会话

- 分离会话

a. 同时按下 `Ctrl+b 再按 d`

或者

b. 输入 `tmux detach `命令

就会将当前会话与窗口分离

```bash
tmux detach
```

上面命令执行后，就会退出当前 Tmux 窗口，但是会话和里面的进程仍然在后台运行

- 查看会话

```bash
tmux ls
 
# or
tmux list-session
```

- 接入会话

```bash
tmux attach -t <session-name>
```

- 切换会话

```bash
tmux switch -t <session-name>
```



## 参考资料

- <https://www.ruanyifeng.com/blog/2019/10/tmux.html>