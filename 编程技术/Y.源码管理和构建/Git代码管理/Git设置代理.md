对 ssh 设置代理

```bash
Host github.com
    Hostname ssh.github.com
    Port 443
    User git
    ProxyCommand nc -v -x 127.0.0.1:8899 %h %p
```

