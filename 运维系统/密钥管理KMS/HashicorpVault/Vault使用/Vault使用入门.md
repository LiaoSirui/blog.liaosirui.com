## 客户端安装

```bash
dnf install -y yum-utils
dnf config-manager --add-repo https://rpm.releases.hashicorp.com/RHEL/hashicorp.repo
dnf -y install vault
```

## 服务器基础操作

```bash
export VAULT_API_ADDR=https://vault.alpha-quant.tech
export VAULT_SKIP_VERIFY=true
```

登录

```bash
vault login
```

查看服务器状态

```bash
vault status
```

Vault 提供保护 secret 的措施：

- 秘钥的保护机制：秘钥被拆分成 5 份，至少正确输入 3 个才能解封
- 策略控制（权限控制）：可以针对每个 Path 设置策略
- 有效期：Vault 生成的每个令牌（Token）都有有效

## KV

启动 kv 存储

```bash
vault secrets enable kv
```

写入第一个密码

`kv/lsr` 是一个 Path（路径），可以简单理解为数据库中的一个表。并不是 kv 数据库当中的 key

```bash
vault write kv/aq value=alpha-quant
vault write kv/lsr l=liao sr=sirui
```

读取一条数据

```bash
vault read kv/aq
```

新建策略文件：在 aq 这个路径下，具有只读权限

```bash
vault policy write aq-readonly - << EOF
path "kv/aq" {
     capabilities = ["read"]
}
EOF
```

生成对 `kv/aq`  具有只读权限的 Token

```bash
vault token create -policy="aq-readonly"
```

此处生成了新的 Token， 有效期 768 小时（32 天）

使用新生成的 Token 登录，无需退出，直接再执行 login 即可

```bash
vault login hvs.CAESIKPoUXrH9I_P3x-WxzgXyOZq9F
```

验证新生成的 Token

```bash
vault read kv/aq

# permission denied
vault write kv/aq value=c1
```

## Python SDK 调用

HVAC 是官方 Python 客户端，支持读取/写入 secret

```bash
pip install "hvac[parser]"
```

