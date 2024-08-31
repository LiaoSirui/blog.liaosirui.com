Ssh 默认会把你每个你访问过计算机的公钥（public key）都记录在 `~/.ssh/known_hosts`

当再次访问该主机时，OpenSSH 会校对公钥，如果公钥不同，OpenSSH 则发出警告， 避免你受到 DNS Hijack 之类的攻击

特殊情况下，需要忽略，修改配置文件 `~/.ssh/config`，加上如下参数：

```
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

