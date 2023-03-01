except 主要进行自动化的交互，except 能够模拟用户的输入，也可以读取标准输出，这非常适合需要用户输入的场景

expect 关键命令

- `send`”向进程发送字符串，用于模拟用户的输入，注意一定要加 `\r` 回车
- `expect`：从进程接收字符串
- `spawn`：启动进程（由 spawn 启动的进程的输出可以被 expect 所捕获）
- `interact`：用户交互

利用 except 完成 ssh 密码登录

```bash
#!/usr/bin/env bash

read -r -p "please put IP address:" SSH_IP
read -r -p "please put username:" SSH_USERNAME
read -r -p "please put password:" SSH_PASSWORD

/usr/bin/expect <<-__END__
set timeout 2000
spawn ssh -l "${SSH_USERNAME}" "${SSH_IP}"
expect {
    "yes/no" {send "yes\r";exp_continue}
    "*Y/N" {send "Y\r";exp_continue}
    "*password*" {send "${SSH_PASSWORD}\r"}
}
expect {
    "#*" {
        send "dnf update -y\r"
        send "exit\r"
    }
}
#interact
expect eof
exit
__END__

```

