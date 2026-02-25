## 配置自动解封密提供者（Vault 1）

启用 transit

```bash
vault secrets enable transit

vault write -f transit/keys/autounseal
```

创建一个名为 `autounseal` 的策略

```bash
vault policy write autounseal -<<EOF
path "transit/encrypt/autounseal" {
   capabilities = [ "update" ]
}

path "transit/decrypt/autounseal" {
   capabilities = [ "update" ]
}
EOF

```

创建 token

```bash
vault token create -orphan -policy="autounseal" \
   -wrap-ttl=120 -period=24h \
   -field=wrapping_token > wrapping-token.txt

```

生成的令牌是传递给 Vault 2（另外一个 Vault） 以解密根密钥并解封 Vault 的

## 配置自动解封（Vault 2）

unwrap token

```bash
export VAULT_ADDR="https://vault.alpha-quant.tech"
export VAULT_API_ADDR="https://vault.alpha-quant.tech"

vault unwrap -field=token $(cat wrapping-token.txt)
```

运行 **Vault 2** 服务器，然后设置 `VAULT_TOKEN` 环境变量

`address` points to the Vault server listening to port **8200** (Vault 1). The `key_name` and `mount_path` match to what you created

```bash
export VAULT_TOKEN="hvs...."

tee config-autounseal.hcl <<EOF
disable_mlock = true
ui=true

storage "raft" {
   path    = "./vault/vault-2"
   node_id = "vault-2"
}

listener "tcp" {
  address     = "127.0.0.1:8100"
  tls_disable = "true"
}

seal "transit" {
  address = "$VAULT_ADDR"
  disable_renewal = "false"
  key_name = "autounseal"
  mount_path = "transit/"
  tls_skip_verify = "true"
}

api_addr = "http://127.0.0.1:8100"
cluster_addr = "https://127.0.0.1:8101"
EOF

```

创建路径

```bash
mkdir -p vault/vault-2
```

启动服务

```bash
vault server -config=config-autounseal.hcl
```

初始化

```bash
VAULT_ADDR=http://127.0.0.1:8100 vault operator init
```

为 Vault 2 服务器运行 `Vault 状态`以验证初始化和封装状态。

## 验证自动解封

重启 vault2

查看状态

```bash
VAULT_ADDR=http://127.0.0.1:8100 vault status
```

# AliCloud KMS

