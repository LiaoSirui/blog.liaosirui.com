## KV 引擎

默认 KV 无版本控制，易导致数据丢失。KV v2 支持版本历史

1. 在 UI：`Secret Engines` > `Enable new engine`
2. 选择 `KV`，比如 `Maximum number of versions`最多保留几个版本输入 `2`，路径 `kv`
3. 启用后，创建 `/dev_db` secret（同上）

![image-20251206141618463](./.assets/KV引擎/image-20251206141618463.png)

注意命令行创建的方式：

```bash
# 不指定则默认路径为 kv，版本为 kv-v1
vault secrets enable kv

# 命令行创建 kv-v2，需要执行
vault secrets enable -path=kv kv-v2
vault secrets enable kv-v2 # 默认创建 path 为 kv-v2
```

API 获取最新版本：

```bash
curl \
  --header "X-Vault-Token: ..." \
  --request GET \
  https://vault.alpha-quant.tech/v1/kv/data/dev_db
```

或者

```bash
vault kv get -version=1 -mount="kv" "dev_db"
```

创建新版本：在 UI 点击 `Create new`，修改（如 `port` 从字符串 “3306” 改数字 3306）

直接请求获取最新版本

获取特定版本：

```bash
curl \
  --header "X-Vault-Token: ..." \
  --request GET \
  'https://vault.alpha-quant.tech/v1/kv/data/dev_db?version=1'
```

### kv 引擎使用

提交数据

```bash
vault kv put kv/creds1 passcode=my-long-passcode
vault kv put kv/creds2 name=test passwd=123456
```

或者使用官方更推荐的 v2 版本的写法： 

```bash
vault kv put -mount="kv" creds3 passcode=my-long-passcode
vault kv put -mount="kv" creds4 name=test passwd=123456
```

如果要给 kv/creds1 增加一个额外的键值对，使用 patch 命令。如果使用 put 命令的话，需要把当前已有的键值对的内容带上，否则原先内容会被覆盖掉

```bash
 vault kv patch kv/creds1 alive=48h
```

查看数据

```bash
vault kv get kv/creds1
vault kv get -mount=kv creds1

# 查看元数据
vault kv get -output-curl-string kv/creds1
```

列出路径下的清单

```bash
# vault kv list kv     
Keys
----
creds1
creds2
creds3
creds4
```

### 回滚历史版本

提交数据

```bash
vault kv put kv/creds-his aliyun_oss=['ak-22222','secret-11111']
vault kv put kv/creds-his aliyun_oss=['ak-22222','secret-11111']
vault kv put kv/creds-his aliyun_oss=['ak-22222','secret-11111'] tencent_oss=['ak-22222','secret-11111'] huawei_oss=['ak-333','secret-444']
```

查看数据

```bash
vault kv get kv/creds-his
# 当前数据：
# version            3
```

查看历史版本数据

```bash
vault kv get -version=2 kv/creds-his
```

假设版本 2 就是正确的数据，下面执行 rollback 命令回滚

```bash
vault kv rollback -version=2 kv/creds-his
# 当前数据：
# version            4
```

### 删除

delete 命令删除 Key/Value 机密引擎指定路径上的数据。如果使用 K/V Version 2，它的版本化数据不会被完全删除，而是标记为已删除并且不会在正常的读取请求中返回

```bash
vault kv delete kv/creds-his
# 如不带-versions= 参数表示删除最新版本

vault kv delete -versions=1 kv/creds-his
```

再次查询这个元素，可以看到值已经查不到（默认查询最新的 version 信息）

```bash
vault kv get kv/creds-his
```

查看历史版本仍能获取数据

```bash
vault kv get -version=2 kv/creds-his
```

使用 list 接口还是能看到 creds-his 这个元素

```bash
# vault kv list kv       

Keys
----
creds-his
creds1
creds2
creds3
creds4
```

如果要把元数据也删除，可以使用下面的命令

```bash
vault kv metadata delete kv/creds-his
```

kv undelete 命令，撤销对 K/V 存储中指定路径上的指定版本的数据删除。它可以恢复数据，允许它在获取请求时返回

```bash
# 当前删除了最新的 version: 2
vault kv delete kv/creds1
vault kv get kv/creds1

# undelete 必须指定版本
vault kv undelete -versions=2 kv/creds1
vault kv get kv/creds1
```

kv destroy 永久删除

``` bash
vault kv destroy -versions=1 kv/creds1
```

## 策略

创建策略

```bash
vault policy write my-kv-read-policy - << EOF
path "kv/data/creds1" {
    capabilities = ["read"]
}
path "kv/data/creds2" {
    capabilities = ["read","update"]
}
EOF
```

如果对于 v1 版本的 kv secret 引擎，则不需要 data 路径，类似如下：

```
path "kv/creds1" {
    capabilities = ["read"]
}
path "kv/creds2" {
    capabilities = ["read","update"]
}
```

生成 Token 并指定策略

```bash
vault token create -policy="my-kv-read-policy"
```

列出上面这个 token 的明细情况

```bash
vault token lookup hvs...
```

vault token lookup 除了可以基于 token 查询，还可以基于 `-accessor` 查询

```bash
vault token lookup -accessor ...
```

查看 policy 信息

```bash
# 列出当前 policy
vault policy list

# 查看新创建的 policy 的内容
vault policy read my-kv-read-policy
```

## Python SDK 调用

示例代码（读取 KV）

```python
import hvac

client = hvac.Client(
    url='http://[你的IP]:8300',
    token="[你的root_token]"
)
is_authenticated = client.is_authenticated()
assert is_authenticated, print(is_authenticated)

# 读取最新版本
read_response = client.secrets.kv.read_secret_version(
    path='/dev_db',
    raise_on_deleted_version=False
)
print(read_response)

# 读取版本 1
read_response_v1 = client.secrets.kv.read_secret_version(
    path='/dev_db',
    raise_on_deleted_version=False,
    version=1
)
print(read_response_v1)

```

## 参考文档

KV 引擎：<https://developer.hashicorp.com/vault/docs/secrets/kv>

