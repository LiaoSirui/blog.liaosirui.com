## SSH 远程配置

```bash
Host *
    SendEnv LANG LC_*
    StrictHostKeyChecking no
    ServerAliveInterval 10
    ServerAliveCountMax 100

Include ssh_config.d/*
```

## 跳板

ssh 跳板配置如下：

```bash
Host online
    HostName 192.168.146.152
    Port 22
    User root
    ProxyJump root@39.104.51.183
```

使用网络代理

```bash
Host github.com
    HostName ssh.github.com
    Port 443
    User git
    ProxyCommand nc -v -x 127.0.0.1:8899 %h %p
```

## SSH 心跳

服务端设置

```bash
ClientAliveInterval 30
ClientAliveCountMax 6
```

或者客户端

```bash
ssh -o ServerAliveInterval=30 -o ServerAliveCountMax 100 yyy@xxx.xxx.xxx.xxx
```

## 忽略公钥校验

Ssh 默认会把你每个你访问过计算机的公钥（public key）都记录在 `~/.ssh/known_hosts`

当再次访问该主机时，OpenSSH 会校对公钥，如果公钥不同，OpenSSH 则发出警告， 避免你受到 DNS Hijack 之类的攻击

特殊情况下，需要忽略，修改配置文件 `~/.ssh/config`，加上如下参数：

```bash
StrictHostKeyChecking no
```

或者在命令行增加：

```bash
ssh -o StrictHostKeyChecking=no yyy@xxx.xxx.xxx.xxx
```

多个参数可以一起使用

```bash
ssh -o ServerAliveInterval=30 -o StrictHostKeyChecking=no yyy@xxx.xxx.xxx.xxx
```