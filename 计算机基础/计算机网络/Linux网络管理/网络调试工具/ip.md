使用 ip 命令的 up 和 down 选项来启动或关闭某个特定的网络接口，就像 ifconfig 的用法一样。

```bash
# 关闭 eth0 网络接口
ip link set eth0 down

# 打开 eth0 网络接口
ip link set eth0 up
```
