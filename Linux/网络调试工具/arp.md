https://blog.csdn.net/u012206617/article/details/119115346



如果是暂时性 arp 欺骗攻击至此即可，如果网络中常有此问题，继续以下：

```bash
# 如下命令建立 /ect/ip-mac 文件
echo '网关IP地址 网关MAC地址' > /etc/ip-mac
 
# 通过下面的命令查看文件是否写的正确
more /etc/ip-mac
 
# 加载静态绑定 arp 记录
arp -f /etc/ip-mac 
```

例如

```bash
# /etc/ip-mac 
10.244.244.1 00:e2:69:59:b8:82

```



如果想开机自动绑定

```bash
echo 'arp -f /ect/ip-mac' >> /etc/rc.d/rc.local
```

https://cloud.tencent.com/developer/article/1850460