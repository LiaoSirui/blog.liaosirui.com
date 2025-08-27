## Redis ACL

Redis 访问控制列表(ACL)，是一项可以实现限制特定客户端连接可执行命令和键访问的功能，它的工作方式是：客户端连接服务器以后，客户端需要提供用户名和密码用于验证身份：如果验证成功，客户端连接会关联特定用户以及用户相应的权限。

Redis 客户端默认使用用户 default

## 配置 ACL

### 默认规则

默认配置的 Redis 实例 ACL 规则如下：

```bash
127.0.0.1:6379> ACL LIST
1) "user default on sanitize-payload ~* &* +@all"
```

### ACL 规则

启用和禁止用户

- `on`: 启用用户：可以使用这个用户进行验证。
- `off`: 禁止用户：不能使用这个用户进行验证，但已经验证的客户端连接仍然可以继续工作，需要注意的是如果默认（default）用户如果被禁止，默认用户配置将不起作用，新的客户端连接将会不被验证并且需要用户显式发送 AUTH 命令或 HELLO 命令进行验证。

配置有效的用户名密码

- `nopass`：无密码，可以使用任何密码认证该用户，此外还会重置用户配置的所有密码。
- `>password`：给用户设置一个密码，注意用户可以设置多个密码。例如，`>mypass` 会为用户新增一个 `mypass` 密码。
- `<password`：移除某个密码，如果当前密码不存在会报错。
- `#<hashedpassword>`：给用户设置一个哈希密码，哈希密码是使用 `SHA256` 进行哈希处理并转换的一个十六进制字符串。
- `!<hashedpassword>`：移除哈希密码。

允许和禁止命令

- `+`: 添加命令到用户允许执行命令列表。
- `-`: 从用户允许执行命令列表删除命令。
- `+@`: 允许用户执行所有定义在 category 类别中的命令。有效的类别例如 `@admin`, `@set`, `@sortedset` 等等。可以通过使用 `ACL CAT` 命令查看所有预定义的类别，另外一个特殊的类别 `+@all` 意思是所有在当前系统里的命令，以及将来在 Redis 模块中添加的命令。
- `-@`: 类似于 `+@`，但是是从用户可以执行的命令列表中删除特定的命令。
- `+|subcommand`：允许 用户启用一个被禁止命令的子命令，请注意这个命令不允许使用 - 规则，例如 -DEBUG|SEGFAULT，只能使用 + 规则。如果整个命令已经被启用，单独启用子命令没有意义，Redis 会返回错误。
- `allcommands`: `+@all` 的别名. 注意这个会使用户允许执行所有从 Redis 模块中添加的命令。
- `nocommands`: `-@all` 的别名。

允许和禁用特定键以及键权限

- `~<pattern>`：将指定的键模式添加到用户可访问的键模式列表中，键模式是指符合 `Glob` 风格模式（快速匹配字符串的正则表达式）的键。用户具有匹配该模式的键的读写权限，示例：`~objects:*` 。
- `%R~<pattern>`：类似于常规键模式，但仅授予读取的权限。
- `%W~<pattern>`：类似于常规键模式，但仅授予写入的权限。
- `%RW~<pattern>`：`~<pattern>`的别名。
- `allkeys`：`~*`的别名，允许用户访问所有键。
- `resetkeys`：移除所有键模式。

允许和禁用 Pub/Sub 频道

- `&<pattern>`: (Redis 6.2 及更高版本可用) 添加用户可以访问的 Pub/Sub 频道 glob 风格模式。可以指定多个频道模式。
- `allchannels`: `&*` 的别名，允许用户访问所有 Pub/Sub 频道。
- `resetchannels`: 清空允许的频道模式列表，如果用户的 Pub/Sub 客户端无法再访问其相应的频道和/或频道模式，则断开连接。

### 命令分组

- `admin`：管理命令，普通应用程序永远不会需要使用这些命令。包括`REPLICAOF`、`CONFIG`、`DEBUG`、`SAVE`、`MONITOR`、`ACL`、`SHUTDOWN`等。
- `dangerous`：可能危险的命令（每个命令都因为各种原因需要谨慎考虑）。这包括`FLUSHALL`、`MIGRATE`、`RESTORE`、`SORT`、`KEYS、CLIENT`、`DEBUG`、`INFO`、`CONFIG`、`SAVE`、`REPLICAOF`等。
- `connection`： 影响连接或其他连接的命令。这包括`AUTH`、`SELECT`、`COMMAND`、`CLIENT`、`ECHO`、`PING`等。
- `blocking`：可能会阻塞连接，直到被另一个命令释放。
- `fast `： 快速`O(1)`命令。可能会根据参数数量进行循环，但不会根据键中的元素数量进行循环。
- `bitmap`：与位图相关的命令
- `list` ：与列表相关的命令。
- `set` ：与集合相关的命令。
- `sortedset`：与有序集合相关的命令。
- `stream` ：与流相关的命令。
- `string`：与字符串相关的命令。
- `geo`：与地理空间索引相关的命令。
- `hash` ：与哈希相关的命令。
- `hyperloglog` ： 与 `HyperLogLog` 相关的命令。
- `pubsub`： 与发布/订阅相关的命令。
- `transaction` ： 与`WATCH/MULTI/EXEC`相关的命令。
- `scripting` ：与脚本相关的命令。
- `slow` ：所有不是快速命令的命令。
- `write`： 向键（值或元数据）写入。
- `read` ： 从键（值或元数据）读取。请注意，不与键交互的命令既不属于读取也不属于写入类别。
- `keyspace`： 以类型无关的方式对键、数据库或它们的元数据进行写入或读取。包括`DEL`、`RESTORE`、`DUMP`、`RENAME`、`EXISTS`、`DBSIZE`、`KEYS`、`EXPIR`E、`TTL`、`FLUSHALL`等。可能会修改键空间、键或元数据的命令也将具有写入（`write`）类别。仅读取键空间、键或元数据的命令将具有读取（`read`）类别。

### 使用 ACL SETUSER

定义一个 ACL 用户：

```bash
ACL SETUSER testuser
```

SETUSER 命令需要提供用户名以及与用户相关联的 ACL 规则

上面的例子里没有提供任何与用户相关联的规则。这样只是创建一个用户，如果用户不存在的话，会使用默认 ACL 配置属性创建。如果用户已经存在，这条命令将不起任何作用。来看一下默认用户的状态：

```bash
"user testuser off sanitize-payload resetchannels -@all"
```

默认创建的用户没有使用任何命令的权限

定义一个开启的，设置密码的，只能访问 GET 命令并只能访问 cached：键模式的用户。

```bash
ACL SETUSER testuser >p1pp0 ~cached:* +get
```

### 外部 ACL 文件

指定配置选项 aclfile

```bash
aclfile /etc/redis/users.acl
```

## 配置示例

```
user default on nopass ~* &* +@all

# 用户访问 Pub/Sub 频道
user sub_user on nopass resetkeys &* +@pubsub

# Stream
user sub_user on nopass %R~* &* +@stream

```

## 参考资料

- <https://redis.io/commands/auth>
- <https://redis.ac.cn/docs/latest/operate/oss_and_stack/management/security/acl/>

- <https://juejin.cn/post/7422656001026326580>
