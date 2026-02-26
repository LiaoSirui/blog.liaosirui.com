## 安装

Vault 是一个基于身份的密钥管理和数据加密系统，提供对 Token、密码、证书、API Key 等常见敏感凭据的安全存储和控制，可有效解决应用系统中对敏感信息的硬编码问题。

通过远程仓库获取。执行以下命令，添加并更新仓库。

```bash
helm repo add hashicorp https://helm.releases.hashicorp.com
helm repo update
```

执行以下命令，在名为 vault 的命名空间中安装 Vault

```bash
helm install vault -n hashicorp-vault-system hashicorp/vault \
    --set='server.ha.enabled=true' \
    --set='server.ha.raft.enabled=true' \
    --set='server.dataStorage.size=20Gi' \
    --set='server.dataStorage.storageClass=nfs-client'
```

## 初始化和解封 Vault

查看 Vault 第一次启动后的状态

```bash
kubectl exec -it -n hashicorp-vault-system vault-0 -- vault status
```

预期输出

```bash
Key                     Value
---                     -----
Initialized             false
Sealed                  true
Storage Type            raft
HA Enabled              true
```

当`Initialized`为`false`，`Sealed`为`true`时，表明 Vault 未进行初始化，且没有解封（Unseal）。您需要进行后续的初始化和解封操作

执行以下命令，初始化 Vault。

```bash
kubectl exec -it vault-0 -n hashicorp-vault-system -- vault operator init -key-shares=5 -key-threshold=3 -format=json > cluster-keys.json
```

初始化过程中，系统生成了 5 个`shares`，并指定解封次数`threshold`为 3。

由于以上`unseal_threshold`设置为 3，所以此处需选取 3 个 Unseal key 进行解封，分别执行 1 次，共需执行 3 次。

```bash
kubectl exec -it vault-0 -n hashicorp-vault-system -- vault operator unseal
```

执行以下命令，查看 vault-0 的状态。

```bash
kubectl exec -it -n hashicorp-vault-system vault-0 -- vault status
```

预期输出

```bash
Key                     Value
---                     -----
Seal Type               shamir
Initialized             true
Sealed                  false
Total Shares            5
Threshold               3
```

预期输出表明，`vault-0`已初始化完成。

如需查看 Raft 节点，可通过 root Token 登录节点进行查看

```bash
kubectl exec -it -n hashicorp-vault-system vault-0 -- vault login
```

执行以下命令，查看 Raft 节点

```bash
kubectl exec -it -n hashicorp-vault-system vault-0 -- vault operator raft list-peers
```

预期输出：

```bash
Node                                    Address                        State     Voter
----                                    -------                        -----     -----
3d2cb94d-a212-5864-24ad-4d1f19863ed4    vault-0.vault-internal:8201    leader    true
```

执行以下命令，添加 Vault 节点

```bash
kubectl exec -it -n hashicorp-vault-system vault-1 -- vault operator raft join http://vault-0.vault-internal:8200
kubectl exec -it -n hashicorp-vault-system vault-2 -- vault operator raft join http://vault-0.vault-internal:8200
```

分别执行以下命令，解封添加的 Vault 节点。

每个节点至少要用不同的 Unseal key 执行 3 次，共需执行 6 次。

```bash
kubectl exec -it vault-1 -n hashicorp-vault-system -- vault operator unseal
kubectl exec -it vault-2 -n hashicorp-vault-system -- vault operator unseal
```

执行以下命令，查看节点添加结果。

```bash
vault operator raft list-peers
```

预期输出：

```bash
Node                                    Address                        State       Voter
----                                    -------                        -----       -----
3d2cb94d-a212-5864-24ad-4d1f19863ed4    vault-0.vault-internal:8201    leader      true
3e3ec6ca-cba7-abb6-5ddd-f06750c9ca32    vault-1.vault-internal:8201    follower    true
0241a6e5-ba73-6dad-7d16-2ec8d7e7697f    vault-2.vault-internal:8201    follower    true
```

预期输出表明，`vault-1` 和`vault-2`节点已添加成功。

## 通过 Service 调用 Vault

```bash
# kubectl get svc -n hashicorp-vault-system

NAME                       TYPE        CLUSTER-IP     EXTERNAL-IP   PORT(S)             AGE
vault                      ClusterIP   10.4.129.253   <none>        8200/TCP,8201/TCP   13m
vault-active               ClusterIP   10.4.115.28    <none>        8200/TCP,8201/TCP   13m
vault-agent-injector-svc   ClusterIP   10.4.2.180     <none>        443/TCP             13m
vault-internal             ClusterIP   None           <none>        8200/TCP,8201/TCP   13m
vault-standby              ClusterIP   10.4.51.84     <none>        8200/TCP,8201/TCP   13m
vault-ui                   ClusterIP   10.4.47.182    <none>        8200/TCP            13m
```

- `vault`和`vault-internal`为整个 Vault 集群节点的负载均衡，其中，`vault-internal`为 Headless 的 SVC。
- `vault-active`为 Raft 选出的 leader 节点。
- `vault-standby`为 Raft 中的 follower 节点。