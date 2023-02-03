## 服务端安装

在节点 `10.244.244.201` 上来安装 NFS 服务，数据目录：`/data/nfs`

关闭防火墙

```bash
systemctl stop firewalld.service

systemctl disable firewalld.service
```

安装配置 nfs

```bash
dnf -y install nfs-utils rpcbind
```

共享目录设置权限：

```bash
mkdir -p /data/nfs

# chown -R nobody:nobody /data/nfs
chmod -R 755 /data/nfs
```

配置 nfs，nfs 的默认配置文件在 `/etc/exports` 文件下，在该文件中添加下面的配置信息：

```bash
> vim /etc/exports

/data/nfs  *(rw,sync,no_root_squash)
```

配置说明：

- `/data/nfs`：是共享的数据目录
- *：表示任何人都有权限连接，当然也可以是一个网段，一个 IP，也可以是域名
- rw：读写的权限
- sync：表示文件同时写入硬盘和内存
- no_root_squash：当登录 NFS 主机使用共享目录的使用者是 root 时，其权限将被转换成为匿名使用者，通常它的 UID 与 GID，都会变成 nobody 身份

启动服务 nfs 需要向 rpc 注册，rpc 一旦重启了，注册的文件都会丢失，向他注册的服务都需要重启

注意启动顺序，先启动 rpcbind

```bash
> systemctl start rpcbind.service
> systemctl enable rpcbind
> systemctl status rpcbind
● rpcbind.service - RPC Bind
     Loaded: loaded (/usr/lib/systemd/system/rpcbind.service; enabled; vendor preset: enabled)
     Active: active (running) since Fri 2023-02-03 17:45:23 CST; 6s ago
TriggeredBy: ● rpcbind.socket
       Docs: man:rpcbind(8)
   Main PID: 1487901 (rpcbind)
      Tasks: 1 (limit: 819961)
     Memory: 1.5M
        CPU: 8ms
     CGroup: /system.slice/rpcbind.service
             └─1487901 /usr/bin/rpcbind -w -f

Feb 03 17:45:23 devmaster systemd[1]: Starting RPC Bind...
Feb 03 17:45:23 devmaster systemd[1]: Started RPC Bind.
```

看到上面的 Started 证明启动成功了

然后启动 nfs 服务：

```bash
> systemctl start nfs-server.service
> systemctl enable nfs-server.service
> systemctl status nfs-server.service
● nfs-server.service - NFS server and services
     Loaded: loaded (/usr/lib/systemd/system/nfs-server.service; enabled; vendor preset: disabled)
    Drop-In: /run/systemd/generator/nfs-server.service.d
             └─order-with-mounts.conf
     Active: active (exited) since Fri 2023-02-03 17:46:41 CST; 18s ago
   Main PID: 1488678 (code=exited, status=0/SUCCESS)
        CPU: 9ms

Feb 03 17:46:41 devmaster systemd[1]: Starting NFS server and services...
Feb 03 17:46:41 devmaster systemd[1]: Finished NFS server and services.
```

同样看到 Started 则证明 NFS Server 启动成功

另外我们还可以通过下面的命令确认下：

```bash
> rpcinfo -p|grep nfs
    100003    3   tcp   2049  nfs
    100003    4   tcp   2049  nfs
    100227    3   tcp   2049  nfs_acl
```

查看具体目录挂载权限：

```bash
> cat /var/lib/nfs/etab
/data/nfs	*(rw,sync,wdelay,hide,nocrossmnt,secure,no_root_squash,no_all_squash,no_subtree_check,secure_locks,acl,no_pnfs,anonuid=65534,anongid=65534,sec=sys,rw,secure,no_root_squash,no_all_squash)
```

到这里我们就把 nfs server 给安装成功了

## 客户端安装

然后就是前往节点安装 nfs 的客户端来验证，安装 nfs 当前也需要先关闭防火墙：

```bash
systemctl stop firewalld.service
systemctl disable firewalld.service
```

然后安装 nfs

```bash
dnf -y install nfs-utils rpcbind
```

安装完成后，和上面的方法一样，先启动 rpc、然后启动 nfs：

```bash
systemctl start rpcbind.service
systemctl enable rpcbind.service

systemctl start nfs-server.service
systemctl enable nfs-server.service

```

挂载数据目录客户端启动完成后，在客户端来挂载下 nfs 测试下

首先检查下 nfs 是否有共享目录：

```bash
> showmount -e 10.244.244.101
Export list for 10.244.244.201:
/data/nfs *
```

然后我们在客户端上新建目录：

```bash
mkdir -p /data/nfs
```

将 nfs 共享目录挂载到上面的目录：

```bash
mount -t nfs 10.244.244.201:/data/nfs /data/nfs
```

挂载成功后，在客户端上面的目录中新建一个文件，然后我们观察下 nfs 服务端的共享目录下面是否也会出现该文件：

```bash
touch /data/nfs/test.txt
```

然后在 nfs 服务端查看：

```bash
> ls -al /data/nfs/test.txt
-rw-r--r-- 1 root root 0 Feb  3 17:52 /data/nfs/test.txt
```

如果上面出现了 test.txt 的文件，那么证明 nfs 挂载成功了。

写入 fstab

```bash
10.244.244.201:/data/nfs /data/nfs nfs defaults,nolock,retrans=2,_netdev 0 0
```

