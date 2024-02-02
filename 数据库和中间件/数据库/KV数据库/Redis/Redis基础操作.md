
## 连接 Redis

在命令行终端执行如下命令启动 Redis-client：

```bash
redis-cli -h 10.24.8.1 -p 6379
```

使用交互性更强的 iredis：

```bash
pip3 install iredis

iredis -h 10.24.8.1 -p 6379
```

有的环境下，redis 交互环境可能出现中文乱码的情况，解决办法是用下列命令启动 redis 客户端：

```bash
redis-cli --raw
```

## Redis String

字符串是一种最基本、最常用的 Redis 值类型。

Redis 字符串是二进制安全的，这意味着一个 Redis 字符串能包含任意类型的数据，例如： 一张经过 base64 编码的图片或者一个序列化的 Ruby 对象。通过这样的方式，Redis 的字符串可以支持任意形式的数据，但是对于过大的文件不适合存入 redis，一方面系统内存有限，另外一方面字符串类型的值最多能存储 512M 字节的内容。

可以使用 set 和 get 命令来创建和检索 strings。注意：set 命令将取代现有的任何已经存在的 key。

```bash
10.24.8.1:6379> set my_key some_value
OK

10.24.8.1:6379> get my_key
"some_value"
```

set 命令还有一个提供附加参数的选项，能够让 set 命令只有在没有相同 key 的情况下成功：

```bash
10.24.8.1:6379> set my_key some_value
OK

10.24.8.1:6379> get my_key
"some_value"

10.24.8.1:6379> set my_key new_value NX
(nil)
```

可以让 set 命令在有相同 key 值的情况下成功：

```bash
10.24.8.1:6379> set my_key some_value
OK

10.24.8.1:6379> get my_key
"some_value"

10.24.8.1:6379> set my_key new_value XX
OK
```

即使 string 是 Redis 的基本类型，也可以对其进行其他操作，例如加法器：

```bash
10.24.8.1:6379> set counter 100
OK

10.24.8.1:6379> get counter
"100"

10.24.8.1:6379> incr counter
(integer) 101

10.24.8.1:6379> incrby counter 50
(integer) 151
```

incr 命令让 the value 成为一个整数，运行一次 incr 便加一。incrby 命令便是一个加法运算。类似的命令如减法运算为： decr 和 decrby。

可以运用 mset 和 mget 命令一次性完成多个 key-value 的对应关系，使用 mget 命令，Redis 返回一个 value 数组：

```bash
10.24.8.1:6379> mset a 10 b 20 c 30
OK

10.24.8.1:6379> mget a b c
1) "10"
2) "20"
3) "30"
```

## Redis List

Redis 列表是简单的字符串列表，按照插入顺序排序。

可以添加一个元素到列表的头部（左边）或者尾部（右边），lpush 命令插入一个新的元素到头部，而 rpush 命令插入一个新元素到尾部。

当这两个操作中的任一操作在一个空的 Key 上执行时就会创建一个新的列表。

如果一个列表操作清空一个列表，那么对应的 key 将被从 key 空间删除。

```bash
10.24.8.1:6379> rpush my_list A
(integer) 1

10.24.8.1:6379> rpush my_list B
(integer) 2

10.24.8.1:6379> lpush my_list first
(integer) 3

10.24.8.1:6379> lrange my_list 0 -1
1) "first"
2) "A"
3) "B"
```

lrange 需要两个索引，0 表示 list 开头第一个，-1 表示 list 的倒数第一个，即最后一个。-2 则是 list 的倒数第二个，以此类推。

可以一次加入多个元素放入 list：

```bash
10.24.8.1:6379> rpush my_list 1 2 3 4 5 "foo bar"
(integer) 9

10.24.8.1:6379> lrange my_list 0 -1
1) "first"
2) "A"
3) "B"
4) "1"
5) "2"
6) "3"
7) "4"
8) "5"
9) "foo bar"
```

在 Redis 的命令操作中，还有一类重要的操作 pop，它可以弹出一个元素，简单的理解就是获取并删除第一个元素，和 push 类似的是它也支持双边的操作，可以从右边弹出一个元素也可以从左边弹出一个元素，对应的指令为 rpop 和 lpop：

```bash
10.24.8.1:6379> rpush my_list a b c d
(integer) 4

10.24.8.1:6379> lrange my_list 0 -1
1) "a"
2) "b"
3) "c"
4) "d"

10.24.8.1:6379> rpop my_list
"d"

10.24.8.1:6379> lrange my_list 0 -1
1) "a"
2) "b"
3) "c"

10.24.8.1:6379> lpop my_list
"a"

10.24.8.1:6379> lrange my_list 0 -1
1) "b"
2) "c"
```

一个列表最多可以包含 4294967295（2 的 32 次方减一）个元素，这意味着它可以容纳海量的信息，最终瓶颈一般都取决于服务器内存大小。

### List 阻塞

理解阻塞操作对一些请求操作有很大的帮助，关于阻塞操作的作用，这里举一个例子。

假如你要去楼下买一个汉堡，一个汉堡需要花一定的时间才能做出来，非阻塞式的做法是去付完钱走人，过一段时间来看一下汉堡是否做好了，没好就先离开，过一会儿再来，而且要知道可能不止你一个人在买汉堡，在你离开的时候很可能别人会取走你的汉堡，这是很让人烦的事情。

阻塞式就不一样了，付完钱一直在那儿等着，不拿到汉堡不走人，并且后面来的人统统排队。

Redis 提供了阻塞式访问 brpop 和 blpop 命令。用户可以在获取数据不存在时阻塞请求队列，如果在时限内获得数据则立即返回，如果超时还没有数据则返回 nil。

```bash
10.24.8.1:6379> brpop new_list 10
(nil)

10.24.8.1:6379> brpop my_list 10
1) "my_list"
2) "c"
```

### List 常见应用场景

分析 List 应用场景需要结合它的特点，List 元素是线性有序的。

很容易就可以联想到聊天记录，你一言我一语都有先后，因此 List 很适合用来存储聊天记录等顺序结构的数据。

## Redis Hashes

Redis Hashes 是字符串字段和字符串值之间的映射，因此它们是展现对象的完整数据类型。

例如一个有名、姓、年龄等等属性的用户：一个带有一些字段的 hash 仅仅需要一块很小的空间存储，因此你可以存储数以百万计的对象在一个小的 Redis 实例中。

哈希主要用来表现对象，它们有能力存储很多对象，因此你可以将哈希用于许多其它的任务。

hmset 命令设置一个多域的 hash 表，hget 命令获取指定的单域，hgetall 命令获取指定 key 的所有信息。hmget 类似于 hget，只是返回一个 value 数组。

```bash
10.24.8.1:6379> hmset user:1000 username cyril birth_year 1977 verified 1
"OK"

10.24.8.1:6379> hget user:1000 username
"cyril"

10.24.8.1:6379> hget user:1000 birth_year
"1977"

10.24.8.1:6379> hgetall user:1000
1) "username"
   "cyril"
2) "verified"
   "1"
3) "birth_year"
   "1977"
```

```bash
10.24.8.1:6379> hmget user:1000 username birth_year no-such-field
1) "cyril"
2) "1977"
3) (nil)
```

同样可以根据需要对 hash 表的表项进行单独的操作，例如 hincrby：

```bash
10.24.8.1:6379> hincrby user:1000 birth_year 10
(integer) 1987

10.24.8.1:6379> hincrby user:1000 birth_year 10
(integer) 1997
```

## Redis 无序集合

Redis 集合（Set）是一个无序的字符串集合。

可以以 `O(1)` 的时间复杂度（无论集合中有多少元素时间复杂度都是常量）完成添加、删除以及测试元素是否存在。

Redis 集合不允许包含相同成员的属性，多次添加相同的元素，最终在集合里只会有一个元素，这意味着它可以非常方便地对数据进行去重操作。

Redis 集合支持一些服务端的命令从现有的集合出发去进行集合运算，因此可以在非常短的时间内进行合并（unions），求交集（intersections），找出不同的元素（differences of sets）。

sadd 命令产生一个无序集合，返回集合的元素个数。

```bash
10.24.8.1:6379> sadd my_set 1 2 3
(integer) 3
```

smembers 用于查看集合。

```bash
10.24.8.1:6379> smembers my_set
1) "1"
2) "2"
3) "3"
```

sismember 用于查看集合是否存在，匹配项包括集合名和元素（用于查看该元素是否是集合的成员）。匹配成功返回 1，匹配失败返回 0。

```bash
10.24.8.1:6379> sismember my_set 3
(integer) 1

10.24.8.1:6379> sismember my_set 30
(integer) 0

10.24.8.1:6379> sismember my_s 3
(integer) 0
```

## Redis 有序集合

Redis 有序集合与普通集合非常相似，是一个没有重复元素的字符串集合。不同之处是有序集合的每一个成员都关联了一个权值，这个权值被用来按照从最低分到最高分的方式排序集合中的成员。集合的成员是唯一的，但是权值可以是重复的。

使用有序集合可以以非常快的速度 `O(log(N))` 添加、删除和更新元素。

因为元素是有序的，所以也可以很快的根据权值（score）或者次序（position）来获取一个范围的元素。访问有序集合的中间元素也是非常快的，因此你能够使用有序集合作为一个没有重复成员的智能列表。在有序集合中，你可以很快捷的访问一切你需要的东西：有序的元素，快速的存在性测试，快速访问集合的中间元素！

zadd 与 sadd 类似，但是在元素之前多了一个参数，这个参数便是用于排序的。形成一个有序的集合。

```bash
10.24.8.1:6379> zadd hackers 1940 "Alan Kay"
(integer) 1

10.24.8.1:6379> zadd hackers 1957 "Sophie Wilson"
(integer) 1

10.24.8.1:6379> zadd hackers 1953 "Richard Stallman"
(integer) 1

10.24.8.1:6379> zadd hackers 1949 "Anita Borg"
(integer) 1

10.24.8.1:6379> zadd hackers 1965 "Yukihiro Matsumoto"
(integer) 1

10.24.8.1:6379> zadd hackers 1914 "Hedy Lamarr"
(integer) 1

10.24.8.1:6379> zadd hackers 1916 "Claude Shannon"
(integer) 1

10.24.8.1:6379> zadd hackers 1969 "Linus Torvalds"
(integer) 1

10.24.8.1:6379> zadd hackers 1912 "Alan Turing"
(integer) 1
```

查看集合：zrange 是查看正序的集合，zrevrange 是查看反序的集合。0 表示集合第一个元素，-1 表示集合的倒数第一个元素。

```bash
10.24.8.1:6379> zrange hackers 0 -1
1) "Alan Turing"
2) "Hedy Lamarr"
3) "Claude Shannon"
4) "Alan Kay"
5) "Anita Borg"
6) "Richard Stallman"
7) "Sophie Wilson"
8) "Yukihiro Matsumoto"
9) "Linus Torvalds"

10.24.8.1:6379> zrevrange hackers 0 -1
1) "Linus Torvalds"
2) "Yukihiro Matsumoto"
3) "Sophie Wilson"
4) "Richard Stallman"
5) "Anita Borg"
6) "Alan Kay"
7) "Claude Shannon"
8) "Hedy Lamarr"
9) "Alan Turing"
```

使用 withscores 参数返回记录值。

```bash
10.24.8.1:6379> zrange hackers 0 -1 withscores
1) 1912 "Alan Turing"
2) 1914 "Hedy Lamarr"
3) 1916 "Claude Shannon"
4) 1940 "Alan Kay"
5) 1949 "Anita Borg"
6) 1953 "Richard Stallman"
7) 1957 "Sophie Wilson"
8) 1965 "Yukihiro Matsumoto"
9) 1969 "Linus Torvalds"
```

## 适合全体类型的常用命令

### EXISTS and DEL

exists key：判断一个 key 是否存在，存在返回 1，否则返回 0。

del key：删除某个 key，或是一系列 key，比如：del key1 key2 key3 key4。成功返回 1，失败返回 0（key 值不存在）。

```bash
10.24.8.1:6379> set my_key hello
OK

10.24.8.1:6379> exists my_key
(integer) 1

10.24.8.1:6379> del my_key
DEL will delete keys, it may cause high latency when the value is big.
Do you want to proceed? (y/n): y
Your Call!!
(integer) 1

10.24.8.1:6379> exists my_key
(integer) 0
```

### TYPE and KEYS

type key：返回某个 key 元素的数据类型

- none：不存在，key 不存在返回空
- string：字符
- list：列表
- set：元组
- zset：有序集合
- hash：哈希

keys key—pattern：返回匹配的 key 列表，比如：keys foo* 表示查找 foo 开头的 keys。

```bash
10.24.8.1:6379> set my_key x
OK

10.24.8.1:6379> type my_key
"string"

10.24.8.1:6379> keys my*
KEYS will hang redis server, use SCAN instead.
Do you want to proceed? (y/n): y
Your Call!!
1) "mykey"
2) "my_list"
3) "my_set"
4) "mylist"
5) "my_key"

10.24.8.1:6379> del my_key
DEL will delete keys, it may cause high latency when the value is big.
Do you want to proceed? (y/n): y
Your Call!!
(integer) 1

10.24.8.1:6379> keys my*
KEYS will hang redis server, use SCAN instead.
Do you want to proceed? (y/n): y
Your Call!!
1) "mykey"
2) "my_list"
3) "my_set"
4) "mylist"

10.24.8.1:6379> type my_key
"none"
```

### RANDOMKEY

randomkey：随机获得一个已经存在的 key，如果当前数据库为空，则返回空字符串。

```bash
10.24.8.1:6379> randomkey
"a"

10.24.8.1:6379> randomkey
"user:1000"
```

### CLEAR

clear：清除界面或者 Ctrl + L 快捷键

### RENAME and RENAMENX

rename oldname newname：更改 key 的名字，新键如果存在将被覆盖。

renamenx oldname newname：更改 key 的名字，新键如果存在则更新失败。

```bash
10.24.8.1:6379> randomkey
"my_set"

10.24.8.1:6379> rename my_set new_set
RENAME use DELETE command to overwrite exist key, it may cause high latency when the value is big.
Do you want to proceed? (y/n): y
Your Call!!
OK

10.24.8.1:6379> exists my_set
(integer) 0

10.24.8.1:6379> exists new_set
(integer) 1
```

### DBSIZE

dbsize：返回当前数据库的 key 的总数。

```bash
10.24.8.1:6379> dbsize
(integer) 11
```

## Redis 时间相关命令

### 限定 key 生存时间

这同样是一个无视数据类型的命令，对于临时存储很有用处。避免进行大量的 DEL 操作。

expire：设置某个 key 的过期时间（秒），比如：expire bruce 1000 表示设置 bruce 这个 key 1000 秒后系统自动删除，注意：如果在还没有过期的时候，对值进行了改变，那么那个值会被清除。

```bash
10.24.8.1:6379> set my_key some-value
OK

10.24.8.1:6379> expire my_key 10
(integer) 1

# 马上执行此命令
10.24.8.1:6379> get my_key
"some-value"

# 10s后执行此命令
10.24.8.1:6379> get my_key
(nil)
```

结果显示：执行 expire 命令后，马上 get 会显示 key 存在；10 秒后再 get 时，key 已经被自动删除。

### 查询 key 剩余生存时间

限时操作可以在 set 命令中实现，并且可用 ttl 命令查询 key 剩余生存时间。

ttl：查找某个 key 还有多长时间过期，返回时间单位为秒。

```bash
10.24.8.1:6379> set my_key 100 ex 30
OK

10.24.8.1:6379> ttl my_key
(integer) 18

10.24.8.1:6379> ttl my_key
(integer) 12

10.24.8.1:6379> ttl my_key
(integer) -2

10.24.8.1:6379> ttl my_key
(integer) -2

10.24.8.1:6379> ttl my_key
(integer) -2
```

### 清除 key

flushdb：清空当前数据库中的所有键。

flushall：清空所有数据库中的所有键。

## Redis 设置相关命令

Redis 有其配置文件，可以通过 client-command 窗口查看或者更改相关配置。

### CONFIG GET and CONFIG SET

config get：用来读取运行 Redis 服务器的配置参数。

config set：用于更改运行 Redis 服务器的配置参数。

auth：认证密码。

下面针对 Redis 密码的示例：

```text
# 查看密码
10.24.8.1:6379> config get requirepass
requirepass: 

# 设置密码为 test123
10.24.8.1:6379> config set requirepass test123
CONFIG SET will change the server's configs.
Do you want to proceed? (y/n): y
Your Call!!
OK

10.24.8.1:6379> config get requirepass
(error) ERROR Authentication required.

# 认证密码
10.24.8.1:6379> auth test123
OK

10.24.8.1:6379> config get requirepass
requirepass: test123
```

config get 命令是以 list 的 key-value 对显示的，如查询数据类型的最大条目：

```bash
10.24.8.1:6379> config get *max-*-entries*
hash-max-ziplist-entries: 512
set-max-intset-entries: 512
zset-max-ziplist-entries: 128
```

### 重置报告

config resetstat：重置数据统计报告，通常返回值为“OK”。

## 查询信息

`info [section]`：查询 Redis 相关信息。

info 命令可以查询 Redis 几乎所有的信息，其命令选项有如下：

- server: Redis server 的常规信息
- clients: Client 的连接选项
- memory: 存储占用相关信息
- persistence: RDB and AOF 相关信息
- stats: 常规统计
- replication: Master/Slave 请求信息
- cpu: CPU 占用信息统计
- cluster: Redis 集群信息
- keyspace: 数据库信息统计
- all: 返回所有信息
- default: 返回常规设置信息

若命令参数为空，info 命令返回所有信息。
