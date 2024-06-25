使用以下命令检查 `nfsd` 模块支持的 NFS 版本：

```bash
cat /proc/fs/nfsd/versions
```

该命令输出支持的 NFS 版本列表，例如：

```
-2 +3 +4 +4.1
```

其中，前面的符号表示是否启用了对应的版本，`+` 表示启用，`-` 表示禁用。

在某些系统上，NFS 版本配置可能在 `/etc/nfs.conf` 文件中。您可以检查这个文件，确保配置正确：

```
[nfsd]
vers3=y
vers4=y
vers4.1=y
```

![img](.assets/NFS版本/99dgq3h9oq.png)

win 修改

```
HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\ClientForNFS\CurrentVersion\Default
```

- 找到或创建一个名为 `NfsMountProtocol` 的 `DWORD (32-bit) Value`。
- 将其值设置为对应的 NFS 版本：
  - `1` 表示 NFSv2
  - `2` 表示 NFSv3
  - `3` 表示 NFSv4
