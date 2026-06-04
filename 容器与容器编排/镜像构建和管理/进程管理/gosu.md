gosu：实现“Root 启动，非 Root 运行”。它允许容器在初始化（Entrypoint）阶段使用 root 权限执行必要的挂载、权限修复或环境配置，随后直接退居为普通用户启动实际应用，兼顾了容器初始化灵活性与运行时的安全性

处理完用户 / 组后，将切换到指定用户，然后执行指定的进程，gosu 本身不再驻留或完全不在进程生命周期中。这避免了信号传递和 TTY 的所有问题。

```bash
$ docker run -it --rm ubuntu:trusty su -c 'exec ps aux'
USER       PID %CPU %MEM    VSZ   RSS TTY      STAT START   TIME COMMAND
root         1  0.0  0.0  46636  2688 ?        Ss+  02:22   0:00 su -c exec ps a
root         6  0.0  0.0  15576  2220 ?        Rs   02:22   0:00 ps aux

$ docker run -it --rm ubuntu:trusty sudo ps aux
USER       PID %CPU %MEM    VSZ   RSS TTY      STAT START   TIME COMMAND
root         1  3.0  0.0  46020  3144 ?        Ss+  02:22   0:00 sudo ps aux
root         7  0.0  0.0  15576  2172 ?        R+   02:22   0:00 ps aux

$ docker run -it --rm -v $PWD/gosu-amd64:/usr/local/bin/gosu:ro ubuntu:trusty gosu root ps aux
USER       PID %CPU %MEM    VSZ   RSS TTY      STAT START   TIME COMMAND
root         1  0.0  0.0   7140   768 ?        Rs+  02:22   0:00 ps aux
```

一般是在`entrypoint.sh`使用，例如 PG

```bash
#!/bin/bash
set -e

if [ "$1" = 'postgres' ]; then
    chown -R postgres "$PGDATA"

    if [ -z "$(ls -A "$PGDATA")" ]; then
        gosu postgres initdb
    fi

    exec gosu postgres "$@"
fi

exec "$@" 
```

`su/sudo` 和 `gosu` 的区别：

想象你经营一家银行（容器），你是银行经理（Root），拥有所有钥匙。你需要让柜员（普通用户）去坐柜台工作。

1. 使用 su 或 sudo： 你（经理）并没有离开，而是站在柜员身后盯着他。如果有人来打劫（发送停止信号 SIGTERM），劫匪是对着你喊话。但因为你是个中间人，柜员可能根本听不到劫匪的话，还在继续数钱，结果被 “撕票”（强制杀死进程，数据丢失）。
   - 技术解释：sudo 会启动一个新的子进程。你的应用不是 PID 1，它收不到容器运行时发出的停止信号。
2. 使用 gosu： 你（经理）把钥匙交给柜员，帮他把椅子调整好，然后原地变身成了柜员，或者直接消失，把位置完全让给柜员。现在柜台里只有柜员一个人。
   - 技术解释：gosu 使用了 exec 系统调用。它会用应用程序的进程替换掉当前的 shell 进程。你的应用由于 “篡位” 成功，直接变成了 PID 1，能够完美接收并处理所有信号。

如果少了 `exec`，`gosu` 会作为子进程运行，虽然权限对了，但信号传递链条依然是断裂的（虽然 gosu 试图处理信号，但不如直接替换进程来得稳健）。

`Entrypoint (Root)` -> `chown/setup` -> `exec gosu user app`
