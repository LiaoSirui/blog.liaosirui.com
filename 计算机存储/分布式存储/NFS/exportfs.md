Exportfs 命令的常用选项为 -a、-r、-u 和 -v，各选项的含义如下

- **-a**：表示全部挂载或者卸载。
- **-r**：表示重新挂载。
- **-u**：表示卸载某一个目录。
- **-v**：表示显示共享的目录。

当改变 `/etc/exports` 配置文件后，使用 exportfs 命令挂载不需要重启 NFS 服务

首先修改服务端的配置文件，如下所示：

```
> vim /etc/exports # 增加一行:
/tmp/ 192.168.72.0/24(rw,sync,no_root_squash)
```

然后在服务端上执行如下命令：

```bash
> exportfs -arv
exporting 192.168.72.0/24:/tmp
exporting 192.168.72.0/24:/home/nfstestdir
```
