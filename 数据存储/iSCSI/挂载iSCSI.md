## Linux 挂载 iSCSI

安装 iSCSI 的客户端

```bash
dnf install iscsi-initiator-utils -y

# apt-get install open-iscsi
```

定义客户端连机器的名称，一般来说不需要修改

```bash
cat /etc/iscsi/initiatorname.iscsi
```

（可选）启用 chap 认证

```bash
vim /etc/iscsi/iscsid.conf

# 启用 chap 认证
node.session.auth.authmethod = CHAP
# 认证用户名
node.session.auth.username = username
# 如果需要让 windows 访问 password 需要 12 位以上
node.session.auth.password = password
```

启动 iscsid 服务

```bash
systemctl enable --now iscsid
```

发现存储服务器资源

```bash
# -t 显示输出结果 -p:iscsi 服务器地址
iscsiadm -m discovery \
  --type sendtargets \
  --portal 192.168.100.20

192.168.100.20:3260,1 iqn.2021-11.pip.cc:server
```

登录存储服务器

```bash
# -T:服务器发现的名称 -p：服务器地址 
iscsiadm -m node \
  -T iqn.2021-11.pip.cc:server \
  -p 192.168.100.20 \
  --login
```

设置开机自动注册

``` bash
iscsiadm -m node \
  -T iqn.2021-11.pip.cc:server \
  -p 192.168.100.20 \
  --op update \
  -n node.startup -v automatic
```

注意，fstab 文件中必须指定 `_netdev`，不然重启可能无法正常开机，例如

```bash
/dev/sdb /data ext4 defaults,_netdev 0 0

# 用于 systemd
# systemctl list-units --type=mount
```

卸载卷的方式如下

```bash
iscsiadm -m node \
  -T iqn.2021-11.pip.cc:server \
  -p 192.168.100.20 \
  -u
```

验证是否还存在 iSCSI Session

```bash
iscsiadm -m session -P 3 | grep Attached
```

删除发现 iSCSI 信息

```bash
iscsiadm -m node \
  -T iqn.2021-11.pip.cc:server \
  -o delete
```

`ll /var/lib/iscsi/nodes/` 查看为空，即在客户端删除了 iSCSI Target

查看挂载

```bash
iscsiadm -m node
```

## 增加 LUN

服务端先添加 LUN 授权

查看当前 session

```bash
iscsiadm -m session
```

示例输出：

```bash
tcp: [1] 192.168.200.45:3260,3 iqn.1992-04.com.emc:cx.de412231374885.a6 (non-flash)
tcp: [2] 192.168.200.173:3260,4 iqn.1992-04.com.emc:cx.de412231374885.b6 (non-flash)
```

这里 `[1]` 是 session id， `iqn.1992-04.com.emc:cx.de412231374885.a6` 是 target

触发重新扫描 LUN

```bash
iscsiadm -m node -T iqn.1992-04.com.emc:cx.de412231374885.a6 -R
```

检查设备路径（多路径存储时）

```bash
multipath -ll
```

如果新 LUN 没显示，可强制刷新：

```bash
multipath -r
```

