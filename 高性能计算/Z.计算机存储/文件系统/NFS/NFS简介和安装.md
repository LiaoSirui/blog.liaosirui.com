## NFS 简介

NFS 是 Network File System 的缩写，即网络文件系统

NFS 服务会经常用到，它用于在网络上共享存储。举例来说，假如有 3 台机器 A、B 和 C，它们需要访问同一个目录，且目录中都是图片。传统的做法是把这些图片分别放到 A、B、C 中，但若使用 NFS，只需要把图片放到 A 上，然后 A 共享给 B 和 C 即可。访问 B 和 C 时，是通过网络的方式去访问 A 上的那个目录的

![img](.assets/ZTYjw6KickuDibLneVd3NBdNXpyTiaMhF6XNTLW5oZe4G8ZThSTZCoM9XWwpDGfCPOjoxbplTacPEBwPqMJwQBE0w.png)

## 服务端安装

在节点 `10.244.244.3` 上来安装 NFS 服务，数据目录：`/data/raid10` 和 `/data/sata`

关闭防火墙

```bash
systemctl disable --now firewalld.service
```

安装配置 nfs

```bash
dnf -y install nfs-utils rpcbind
```

共享目录设置权限：

```bash
mkdir -p <NFS目录>

# chown -R nobody:nobody <NFS目录>
chmod -R 755 <NFS目录>
```

配置 NFS（NFS 的默认配置文件在 `/etc/exports` 文件下），在该文件中添加下面的配置信息：

```bash
> vim /etc/exports

/data/raid10 *(rw,sync,no_root_squash)
/data/sata *(rw,sync,no_root_squash)
# 此文件的配置格式为：
# <输出目录> [客户端1 选项（访问权限,用户映射,其他）] [客户端2 选项（访问权限,用户映射,其他）]
```

配置说明：

- `/data/raid10`：是共享的数据目录
- `*`：表示任何人都有权限连接，也可以是一个网段、一个 IP、域名

第三部分：

- 访问权限

  - `rw`：表示读/写

  - `ro`：表示只读

- 数据写入模式

  - `sync`：同步模式，表示内存中的数据实时写入磁盘

  - `async`：非同步模式，表示把内存中的数据定期写入磁盘

- 用户映射

  - `no_root_squash`：加上这个选项后，root 用户就会对共享的目录拥有至高的权限控制，就像是对本机的目录操作一样。但这样安全性降低。当登录 NFS 主机使用共享目录的使用者是 root 时，其权限将被转换成为匿名使用者，通常它的 UID 与 GID，都会变成 nobody 身份

  - `root_squash`：与 `no_root_squash` 选项对应，表示 root 用户对共享目录的权限不高，只有普通用户的权限，即限制了 root

  - `all_squash`：表示不管使用 NFS 的用户是谁，其身份都会被限定为一个指定的普通用户身份

  - `anonuid /anongid`：要和 `root_squash` 以及 `all_squash` 选项一同使用，用于指定使用 NFS 的用户被限定后的 uid 和 gid，但前提是本机的 `/etc/passwd` 中存在相应的 uid 和 gid


启动服务 nfs 需要向 rpc 注册，rpc 一旦重启了，注册的文件都会丢失，向他注册的服务都需要重启

注意启动顺序，先启动 rpcbind

```bash
systemctl enable --now rpcbind
systemctl status rpcbind
```

然后启动 NFS 服务：

```bash
systemctl enable --now nfs-server.service
systemctl status nfs-server.service
```

同样看到 Started 则证明 NFS Server 启动成功

还可以通过下面的命令确认下：

```bash
> rpcinfo -p|grep nfs
    100003    3   tcp   2049  nfs
    100003    4   tcp   2049  nfs
    100227    3   tcp   2049  nfs_acl
```

查看具体目录挂载权限：

```bash
> cat /var/lib/nfs/etab

/data/sata	*(rw,sync,wdelay,hide,nocrossmnt,secure,no_root_squash,no_all_squash,no_subtree_check,secure_locks,acl,no_pnfs,anonuid=65534,anongid=65534,sec=sys,rw,secure,no_root_squash,no_all_squash)
/data/raid10	*(rw,sync,wdelay,hide,nocrossmnt,secure,no_root_squash,no_all_squash,no_subtree_check,secure_locks,acl,no_pnfs,anonuid=65534,anongid=65534,sec=sys,rw,secure,no_root_squash,no_all_squash)
```

到这里 NFS server 给安装完成

## 客户端安装

前往节点安装 NFS 的客户端来验证，安装 NFS 前也需要先关闭防火墙：

```bash
systemctl disable --now firewalld.service
```

然后安装 NFS

```bash
dnf -y install nfs-utils rpcbind
```

安装完成后，和上面的方法一样，先启动 RPC、然后启动 NFS：

```bash
systemctl enable --now rpcbind.service
systemctl enable --now nfs-server.service
```

挂载数据目录客户端启动完成后，在客户端来挂载下 NFS 测试

首先检查下 nfs 是否有共享目录：

```bash
> showmount -e 10.244.244.3

Export list for 10.244.244.3:
/data/sata   *
/data/raid10 *
```

然后我们在客户端上新建目录：

```bash
mkdir -p /mnt/nfs/raid10
```

将 nfs 共享目录挂载到上面的目录：

```bash
mount -t nfs 10.244.244.3:/data/raid10 /mnt/nfs/raid10
```

挂载成功后，在客户端上面的目录中新建一个文件，观察下 NFS 服务端的共享目录下面是否也会出现该文件：

```bash
touch /mnt/nfs/raid10/test.txt
```

然后在 NFS 服务端查看：

```bash
> ls -al /data/raid10/test.txt

-rw-r--r-- 1 root root 0 Jan 18 05:21 /data/raid10/test.txt
```

如果上面出现了 `test.txt` 的文件，那么证明 NFS 挂载成功

如果需要开机自动挂载，写入 fstab，注意 `_netdev` 必须加上，防止 NFS 服务器未启动导致服务器无法启动

```bash
10.244.244.3:/data/raid10 /mnt/nfs/raid10 nfs defaults,nolock,retrans=2,_netdev 0 0
```

