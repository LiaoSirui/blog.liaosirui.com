## 初始化

初始化 vault

```bash
docker compose exec -it vault vault operator init -key-shares=1 -key-threshold=1
# vault operator init
```

注意保存 Unseal Key 和 Initial Root Token（Unseal Key 用于解封 Vault）

```bash
Unseal Key 1:
Initial Root Token:
```

生产环境使用更多 key-shares（至少 3）以实现高可用

## operator 命令

查看 vault 的状态

```bash
vault status
# 封印状态: Sealed 为 true
```

需要 vault operator unseal 命令来执行解封

```bash
vault operator unseal
```

封印 vault <https://developer.hashicorp.com/vault/docs/commands/operator/seal>

该操作会将内存中的 Master Key 抛弃，然后必须再执行一次解封操作才能恢复它。封印操作只需要使用 Root 特权进行一次操作即可完成。

这样的话，如果检测到入侵的迹象，可以用最快的速度锁定 Vault 保存的机密来减少损失。

```bash
vault operator seal
```

operator rotate 命令通过轮替底层加密密钥来保护写入存储后端的数据。它将会在密钥环中安装一个新密钥。这个新密钥用于加密新数据，而环中的旧密钥用于解密旧数

## 审计日志

- <https://developer.hashicorp.com/vault/docs/commands/audit>

开启审计日志

```bash
vault audit enable file file_path="/vault/logs/vault-audit.log"
```

列出审计日志及明细信息

```bash
vault audit list -detailed
```

禁用

```bash
vault audit disable file/
```

## 存储后端

- <https://developer.hashicorp.com/vault/docs/configuration/storage>

可以选择数据库，例如：PG <https://developer.hashicorp.com/vault/docs/configuration/storage/postgresql>、ETCD <https://developer.hashicorp.com/vault/docs/configuration/storage/etcd>

## 参考资料

- <https://www.qikqiak.com/post/deploy-vault-on-k8s/>

