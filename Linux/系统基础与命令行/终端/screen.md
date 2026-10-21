## screen 常用命令

- 新建 screen

```bash
screen -S name
```

- `ctrl + A` 窗口之间切换
- `ctrl + A + D` 打开新窗口
- `ctrl + A + D` 保留后台并退出当前窗口

- 显示当前所有的 screen

```bash
screen -ls
```

- 进入某个 screen

```bash
screen -r [screen id] or [screen name]
```

## 常见问题

使用 `screen -r` 时提示“`There is no screen to be resumed matching xxx`”的解决办法

这个问题常常出现在重新连接服务器时，即上次连接后没有主动断开连接（比如突然断网）

执行 `ps all`，找到无法连接的 screen；状态为 `pause`；直接 `kill` 掉他：`kill -9 <PPID>`

```bash
> ps all
F   UID   PID  PPID PRI  NI    VSZ   RSS WCHAN  STAT TTY        TIME COMMAND
4     0   673     1  20   0   7712   744 -      Ss+  ttyS0      0:00 /sbin/agetty -o -p -- 
0  1000 31875 31874  20   0  14396  4672 wait   Ss   pts/0      0:00 -bash
.............................................
0  1000 32460 31875  20   0  31640  3068 pause  S+   pts/0      0:00 screen -S boss
0  1000 32462 32461  20   0  14320  4456 poll_s Ss+  pts/2      0:00 /bin/bash

> kill -9 31875

# 再重新连接

> screen -r boss
```