<https://help.aliyun.com/document_detail/90529.html#section-jyi-hyd-hbr>

| 参数                       | 说明                                                         |
| :------------------------- | :----------------------------------------------------------- |
| `_netdev`                  | 防止客户端在网络就绪之前开始挂载文件系统。                   |
| 0（`noresvport` 后第一项） | 非零值表示文件系统应由 dump 备份。对于 NAS 文件系统而言，此值默认为 0。 |
| 0（`noresvport` 后第二项） | 该值表示 fsck 在启动时检查文件系统的顺序。对于 NAS 文件系统而言，此值默认为 0，表示 fsck 不应在启动时运行。 |

## windows 挂载

- <https://sf.163.com/help/documents/93857370158059520>
- <https://help.aliyun.com/zh/nas/user-guide/mount-a-general-purpose-nfs-file-system-on-a-windows-ecs-instance>

```bash
mount -o nolock -o mtype=hard -o timeout=60 \\file-system-id.region.nas.aliyuncs.com\ S:
```

进入HKEY_LOCAL_MACHINE > SOFTWARE > Microsoft > ClientForNFS > CurrentVersion> Default

在空白处右键新建 > DWORD(32位)值，创建以下两个注册表项

AnonymousGID，值为 0

AnonymousUID，值为 0

NFS 服务只允许 root 用户挂载，Windows Server 默认挂载用户为 Anonymous，Uid 为 -2，因此没有权限。解决办法就是让 Windows Server 在挂载 NFS 时将 Uid 和 Gid 改成 0

若需要卸载共享目录，请使用如下命令：

```bash
umount S:
```

