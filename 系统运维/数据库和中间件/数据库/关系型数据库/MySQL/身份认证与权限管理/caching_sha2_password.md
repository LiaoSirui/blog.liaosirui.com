## caching_sha2_password 简介

caching_sha2_password 是 MySQL 8.0.4 引入的一个新的身份验证插件，特点：

- sha2_password：其实就是 sha256_password，这是 MySQL5.6 就引入的身份验证插件，其优点是对加盐密码进行多轮 SHA256 哈希，以确保哈希转换更安全。其缺点为它要求使用安全连接或使用 RSA 密钥对进行密码交换的未加密连接，因此其身份验证的效率较低。
- caching：在 sha256_password 的基础上增加缓存，有缓存的情况下不需要加密连接或 RSA 密钥对，已达到安全和效率并存。

caching_sha2_password 对密码安全性要求更高，要求用户认证过程中在网络传输的密码是加密的：

- 如果是 SSL 加密连接，则使用 SSL 证书和密钥对来完成 "对称加密密钥对（在TSL握手中生成）" 的交换，后续使用 "对称加密密钥对" 加密密码和数据。
- 如果是非 SSL 加密连接，则在连接建立时客户端使用 MySQL Server 端的 RSA 公钥加密用户密码，Server 端使用 RSA 私钥解密验证密码的正确性，可以防止密码在网络传输时被窥探。

> SSL 加密连接会不止会加密用户密码，还会加密数据（SQL 请求、返回的结果）；非加密连接只使用 RSA 密钥对进行用户密码的加密。

- **未加密连接是怎么使用 RSA 密钥对进行密码交换的？**

当用户验证成功后，会把用户密码哈希缓存起来。新连接客户端发起登录请求时，MySQL Server 端会判断是否命中缓存，如果没有缓存，对于未加密的连接，caching_sha2_password 插件要求连接建立时使用 RSA 进行加密密码交换，否则报错，其过程为：

- 客户端如果拥有服务端的 RSA 公钥，则使用 `--server-public-key-path` 选项指定 RSA 公钥文件；
- 客户端使用 RSA 公钥对用户密码进行加密，请求连接；
- 服务端使用 RSA 私钥进行解密，验证密码的正确性。

如果客户端没有保存服务端的 RSA 公钥文件，也可以使用 --get-server-public-key 选项从服务器请求公钥，则在建立连接时，服务端会先将 RSA 公钥发送给客户端。

如果 `--server-public-key-path`、`--get-server-public-key` 都没有指定，则会报下面这个经典的错误

```bash
> mysql -h10.244.244.100 -uroot -pabcd1234 --ssl-mode=disable
ERROR 2061 (HY000): Authentication plugin 'caching_sha2_password' reported error: Authentication requires secure connection.
```

指定 `--get-server-public-key` 则能成功登录：

如果 root 用户登陆成功，有了缓存，则下次认证时未加密连接不再要求使用 RSA 密钥对：

注意：上述客户端是指 mysql 默认命令行客户端，`--server-public-key-path`、`--get-server-public-key` 参数也只适用于 mysql 客户端

- **RSA 密钥对保存在哪里？**

RSA 钥对默认保存 MySQL datadir 下，用于非 SSL 连接时的密码加密交换：使用 RSA 公钥加密密码，使用 RSA 私钥解密：

```bash
private_key.pem      RSA公钥
public_key.pem       RSA私钥
```

- **密码哈希缓存何时失效？**

当用户验证成功后，密码哈希会缓存起来，缓存会在以下情况被清理：

1. 当用户的密码被更改时；
2. 当使用 RENAME USER 重命名用户时；
3. 执行 FLUSH PRIVILEGES 时；
4. MySQL 重启。

- **复制用户使用 caching_sha2_password 插件需要注意什么？**

对于 MGR ，如果设置 `group_replication_ssl_mode=DISABLED `，则也必须使用下面的变量来指定 RSA 公钥，否则报错：

- group_replication_recovery_get_public_key ：向服务端请求 RSA 公钥；
- group_replication_recovery_public_key_path ：指定本地 RSA 公钥文件。

设置一个就行，考虑拷贝 RSA 公钥到各节点麻烦，建议设置 `group_replication_recovery_get_public_key=ON `。

对于异步/半同步复制，需要在 change master 命令中指定：`MASTER_PUBLIC_KEY_PATH = 'key_file_path'` 或 `GET_MASTER_PUBLIC_KEY = {0|1}`

含义同上，建议：`GET_MASTER_PUBLIC_KEY = 1`

