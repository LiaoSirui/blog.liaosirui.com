全局代理设置

```bash
git config --global http.proxy socks5://127.0.0.1:8899
git config --global https.proxy socks5://127.0.0.1:8899
```

取消代理

```bash
git config --global --unset http.proxy
git config --global --unset https.proxy
```

只对 GitHub 进行代理

```bash
git config --global http.https://github.com.proxy socks5://127.0.0.1:8899
git config --global https.https://github.com.proxy socks5://127.0.0.1:8899
```

对 ssh 设置代理

```bash
Host github.com
    Hostname ssh.github.com
    Port 443
    User git
    ProxyCommand nc -v -x 127.0.0.1:8899 %h %p
```

