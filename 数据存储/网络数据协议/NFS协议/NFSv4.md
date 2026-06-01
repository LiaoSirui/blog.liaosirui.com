## idmap

NFSv4 默认使用 `用户名@域名` 的方式进行身份映射。当客户端和服务端的：

- Domain（域名）不一致
- 用户/组在两端不存在或 UID/GID 不匹配
-  idmapd 服务未正常工作

就会把无法映射的用户显示为 `nobody:nobody`。

编辑客户端和服务端的 `/etc/idmapd.conf`：

```ini
[General]
# 核心：两端必须完全一致
Domain = example.com

# 详细日志级别（排错用，0-9）
Verbosity = 0

# 本地 realm（Kerberos 场景）
Local-Realms = EXAMPLE.COM

[Mapping]
# 找不到映射时使用的默认用户/组
Nobody-User = nobody
Nobody-Group = nobody

[Translation]
# 映射方式，默认 nsswitch（走 /etc/passwd、LDAP 等）
Method = nsswitch

# 可选：静态映射方法
# Method = static,nsswitch

# 静态映射：把远程用户名映射到本地用户名
# 远程用户@域名 = 本地用户名
# [Static]
# someuser@example.com = localuser
```

验证 Domain

```bash
# 显示当前生效的 domain
nfsidmap -d

# 启动服务
systemctl enable --now nfs-idmapd
```

清除映射缓存

```bash
nfsidmap -c
```

目录属主

```bash
# 获取 NFS 目录属主 UID/GID
TARGET_UID=$(stat -c '%u' /data)
TARGET_GID=$(stat -c '%g' /data)
```

## ACL

NFSv4 支持更细粒度的访问控制列表，可使用以下命令在客户端管理精细权限：

- 查看权限：`nfs4_getfacl /本地挂载点`
- 设置权限：`nfs4_setfacl`

- 编辑模式：`nfs4_editfacl /本地挂载点`

```
A::OWNER@:rxtTncCy        ← 所有者权限
A:g:GROUP@:rxtncy         ← 所属组权限
A::EVERYONE@:rxtncy       ← 其他所有人权限
```

ACE 类型

| 值    | 含义          |
| ----- | ------------- |
| **A** | Allow（允许） |
| D     | Deny（拒绝）  |
| U     | Audit（审计） |
| L     | Alarm（告警） |

标志位（Flags）

| 值   | 含义                    |
| ---- | ----------------------- |
| 空   | 普通用户                |
| g    | 表示这是一个组（group） |
| d    | 目录继承                |
| f    | 文件继承                |
| i    | 仅继承（本身不生效）    |

主体（Principal）

| 值          | 含义                         |
| ----------- | ---------------------------- |
| `OWNER@`    | 文件所有者（对应传统 user）  |
| `GROUP@`    | 文件所属组（对应传统 group） |
| `EVERYONE@` | 所有人（对应传统 other）     |

权限：大写通常表示 "写 / 修改"，小写表示 "读"

| 字母 | 权限名                      | 说明               |
| ---- | --------------------------- | ------------------ |
| r    | read-data / list-directory  | 读数据 / 列目录    |
| w    | write-data / create-file    | 写数据 / 创建文件  |
| a    | append-data / create-subdir | 追加 / 创建子目录  |
| x    | execute                     | 执行 / 进入目录    |
| d    | delete                      | 删除自身           |
| D    | delete-child                | 删除子项（目录用） |
| t    | read-attributes             | 读属性             |
| T    | write-attributes            | 写属性             |
| n    | read-named-attributes       | 读命名属性         |
| N    | write-named-attributes      | 写命名属性         |
| c    | read-ACL                    | 读 ACL             |
| C    | write-ACL                   | 写 ACL             |
| o    | write-owner                 | 修改属主           |
| y    | synchronize                 | 同步               |

