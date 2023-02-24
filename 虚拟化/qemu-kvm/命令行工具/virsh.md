Kvm 虚拟机的 virsh 日常管理命令和配置



查看 vnc 端口

```bash
virsh vncdisplay centos2
```

<https://www.jianshu.com/p/5d22e84f3328>




## 网卡管理

### 桥接网卡

创建桥接网卡

```bash
virsh iface-bridge eth0 br0
```

取消桥接网卡命令

```bash
virsh iface-unbridge br0
```

