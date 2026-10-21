> 这个方法包含了潜在将未加密的凭证保存在磁盘上的操作，因此请谨慎操作

`.netrc` 文件包含自动登录过程使用的登录和初始化信息。它通常驻留在用户的主目录中，但可以使用环境变量 NETRC 设置主目录之外的位置

## 格式

文件 `~/.netrc` 用于设置自动登录时所需要的帐号信息。

```text
machine <code.liaosirui.com> login <username> password <passwd>
default login <username> password <passwd>
```

如果有多个 server 就重复第一行， 分别输入对应的服务器、 用户名和密码即可

每行一条记录中：

- `machine`：your-server
- `login`：your-username
- `password`：your-password

default 行匹配所有主机

除了上面的形式，netrc 文件还支持另外两个设置：

- `account`：用于指定额外的一个用户密码
- `macdef`：用于定义宏

## 用途

netrc 文件可以用于下列程序：

- curl
- ftp
- git
- 其他

## 文件权限

建议将文件授权为 `600`

```bash
chmod 600 ~/.netrc
```
