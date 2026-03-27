ESXI 的 `authorized_keys` 在 `/etc/ssh/keys-root/authorized_keys` 所以 ssh-copy-id 不会成功。

查看自己的公钥

```
cat ~/.ssh/id_rsa.pub
```

把自己的公钥写入到

```
echo "你的公钥" > /etc/ssh/keys-root/authorized_keys
```