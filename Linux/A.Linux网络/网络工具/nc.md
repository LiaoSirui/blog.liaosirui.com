ncat/nc 是一个类似于cat的网络命令，常用语网络读、写、重定向

## 实用 Case

### 使用 nc 传输文件

目标服务器，启动一个端口监听

```bash
nc -l 9999 > save.txt
```

文件所属服务器，用于上传文件

```bash
nc 127.0.0.1 9999 < data.txt
```

也可以走 udp 端口进行文件传输，加上`-u`即可

### 使用 nc 作为代理

单向转发

```bash
cat -l 8080 | ncat 192.168.0.2 80
```

实现双向管道，可以如下

```bash
mkfifo 2way
ncat -l 8080 0<2way | ncat 192.168.0.2 80 1>2way
```

利用 nc 来实现端口转发，借助 `-c` 命令

```bash
ncat -u -l 80 -c 'ncat -u -l 8080'
```
