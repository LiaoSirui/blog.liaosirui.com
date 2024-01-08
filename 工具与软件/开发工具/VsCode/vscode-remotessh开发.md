## VSCode RemoteSSH 开发问题合集

wdinwos ssh 无法使用，设置如下

```json
"remote.SSH.path": "C:\\Program Files\\Git\\usr\\bin\\ssh.exe",
```

通过跳板机远程（跳板机为 Windows）

```bash
Host v2test
  HostName 10.237.106.25
  User root

Host v2test1
  HostName 10.237.113.14
  User root
  Port 22
  ProxyCommand "C:\\Program Files\\Git\\usr\\bin\\ssh.exe" -q -W %h:%p root@10.237.106.25

```

