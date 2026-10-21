## nc 简介

nc 是 netcat 的简写，简单、可靠的网络工具

- （1) 实现任意 TCP/UDP 端口的侦听，nc 可以作为 server 以 TCP 或 UDP 方式侦听指定端口
- （2) 端口的扫描，nc 可以作为 client 发起 TCP 或 UDP 连接
- （3) 机器之间传输文件
- （4) 机器之间网络测速

### 安装 nc

```bash
dnf provides -y nc
```

### 测试 tcp 和 udp 端口

测试 tcp 一般会想到使用 telnet

```bash
telnet 192.168.12.10 22
```

telnet 不支持 udp 协议，所以我们可以使用 nc，nc 可以支持 tcp 也可以支持 udp

```bash
# tcp
nc -z -v -w5 192.168.10.12 22

# udp
nc -z -v -u -w5 192.168.10.12 123
```

## 常用参数

- `-u`: 指定 nc 使用 UDP 协议，默认为 TCP
- `-v`: 输出交互或出错信息
- `-z`: 表示 zero，表示扫描时不发送任何数据
- `-w`: 超时秒数，后面跟数字
- `-l`: 用于指定 nc 将处于侦听模式。指定该参数，则意味着 nc 被当作 server，侦听并接受连接，而非向其它地址发起连接。
- `-p`: 暂未用到（老版本的 nc 可能需要在端口号前加 `-p` 参数）
- `-s`: 指定发送数据的源 IP 地址，适用于多网卡机

## 实例

### 测试 udp

```bash
# 服务端
nc -l -u 4789

# 客户端
nc -u 10.244.244.11 4789 << 'EOF'
test
EOF
```

## 参考文档

<https://wsgzao.github.io/post/nc/>