## ALICloud 引擎

- <https://developer.hashicorp.com/vault/docs/secrets/alicloud>

- <https://developer.hashicorp.com/vault/api-docs/secret/alicloud>

## 使用 ALICloud 引擎

在 alicloud 中创建一个用户 ，名称类似于 hashicorp-vault ，并在“用户授权策略”部分直接将新的自定义策略应用到该用户

创建

```bash
vault secrets enable alicloud
```

写入 AccesKey 信息

```bash
vault write alicloud/config \
    access_key=... \
    secret_key=...
```

查看下写入的内容

```bash
vault read alicloud/config
```

准备新生成的 AK 凭据的权限规则

```bash
# 模拟 DBA 只读权限的策略
vault write alicloud/role/dba-readonly-policy \
    remote_policies='name:AliyunKvstoreReadOnlyAccess,type:System' \
    remote_policies='name:AliyunRDSReadOnlyAccess,type:System' \
    remote_policies='name:AliyunMongoDBReadOnlyAccess,type:System' \
    remote_policies='name:AliyunPolardbReadOnlyAccess,type:System' \
    remote_policies='name:AliyunADBReadOnlyAccess,type:System'

# 模拟 SA 只读权限的策略
vault write alicloud/role/sa-readonly-policy \
    remote_policies='name:AliyunOSSReadOnlyAccess,type:System' \
    remote_policies='name:AliyunECSReadOnlyAccess,type:System' \
    remote_policies='name:AliyunSLBReadOnlyAccess,type:System' \
    remote_policies='name:AliyunNASReadOnlyAccess,type:System'

```

如果要更复杂的策略，官方文档给出的写法类似如下：

```bash
vault write alicloud/role/policy-based \
    inline_policies=-<<EOF
[
    {
        "Statement": [
            {
            "Action": "rds:Describe*",
            "Effect": "Allow",
            "Resource": "*"
            }
        ],
        "Version": "1"
    },
    {...}
]
EOF
```

生成新的 AK 凭据（注意：每执行一次就会生成一个新的 AK 对！）

```bash
vault read alicloud/creds/dba-readonly-policy
vault read alicloud/creds/sa-readonly-policy
```

