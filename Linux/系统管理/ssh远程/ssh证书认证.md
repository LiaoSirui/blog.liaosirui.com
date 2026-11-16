## SSH CA 认证

SSH CA（Certificate Authority）认证体系，它通过证书取代传统的公钥认证，能够优雅地解决大规模服务器集群中密钥管理繁琐、权限回收困难的问题。

SSH CA 体系包含三个核心角色：

（1）CA（证书颁发机构） 

CA 拥有一对密钥：

- CA 私钥：核心安全资产，用于给用户公钥签名，必须严格保管
- CA 公钥：分发到所有服务器，告诉服务器 "凡是由我签名的公钥都是可信的"

（2）用户端（客户端） 

用户需要：

- 生成自己的 SSH 密钥对

- 将公钥提交给 CA 进行签名
- 使用私钥 + 证书进行登录

（3）服务器端 

服务器配置：

- 在 `/etc/ssh/sshd_config` 中添加 `TrustedUserCAKeys /etc/ssh/ca_user_key.pub`
- 重启 SSH 服务

## SSH 证书

与传统的 X.509 证书不同，SSH 证书是在公钥文件基础上追加签名信息，包含丰富的元数据字段：

| 字段                           | 作用                                        |
| ------------------------------ | ------------------------------------------- |
| `principals`                   | 指定允许登录的系统用户，如 `ubuntu`、`root` |
| `valid-after` / `valid-before` | 证书有效期，可签发临时证书                  |
| `force-command`                | 强制登录后只能执行特定命令，适用于堡垒机    |
| `source-address`               | 限制登录来源 IP 地址                        |

这些字段使得权限控制可以在证书层面精细实现，无需在服务器端做额外配置。

## 快速部署

（1）生成 CA 密钥

```bash
ssh-keygen -t ed25519 -f ~/ca_user -C "User CA Key"
```

这会生成 `ca_user`（私钥）和 `ca_user.pub`（公钥）。

（2）配置服务器信任 CA

将 `ca_user.pub` 复制到目标服务器：

```bash
scp ~/ca_user.pub user@server:/tmp/
ssh user@server "sudo mv /tmp/ca_user.pub /etc/ssh/ca_user_key.pub"
```

在服务器上编辑 `/etc/ssh/sshd_config`，添加：

```bash
TrustedUserCAKeys /etc/ssh/ca_user_key.pub
```

重启 SSH 服务：

```bash
sudo systemctl restart sshd
```

（3）为用户签发证书 

假设员工提交了他的公钥 `id_ed25519.pub`，现在为他签发证书：

```bash
ssh-keygen -s ~/ca_user \
    -I "employee_a_2026" \
    -n ubuntu \
    -V +52w \
    id_ed25519.pub
```

参数说明：

- `-s`：指定 CA 私钥
- `-I`：证书标识，用于日志审计
- `-n`：允许登录的用户名（principals）
- `-V`：有效期，这里设置为 52 周

执行后会生成 `id_ed25519-cert.pub`。

（4）用户登录 

用户将证书文件放到 `~/.ssh/` 目录下：

```bash
cp id_ed25519-cert.pub ~/.ssh/
```

登录时 SSH 客户端会自动识别证书：

```bash
ssh ubuntu@server_ip
```

服务器会验证：

- 证书是否由信任的 CA 公钥签名

- principals 中是否包含目标用户名

- 是否在有效期内

全部通过后即允许登录。