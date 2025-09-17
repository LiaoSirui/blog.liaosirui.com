## Vsftpd 简介

Vsftpd（Very Secure FTP Daemon）是一款 GPL 许可的 FTP 服务器软件，旨在提供一种安全但快速的文件传输方式。由于其简单性和对系统资源的高效使用，它在 Linux 用户中非常受欢迎。因此，大多数 Linux 发行版（如 Redhat、Fedora、Ubuntu、Debian 等）都提供这个 FTP 服务器软件包，可以直接从系统的基本仓库中安装

## 安装与配置 vsftpd

安装

```bash
dnf install -y vsftpd
```

启动

```bash
systemctl enable --now vsftpd.service
```

运行以下命令，查看 FTP 服务的端口号

```bash
netstat -antup | grep ftp
```

`/etc/vsftpd`目录下文件说明如下：

- `/etc/vsftpd/vsftpd.conf`是vsftpd的核心配置文件。
- `/etc/vsftpd/ftpusers`是黑名单文件，此文件中的用户不允许访问FTP服务器。
- `/etc/vsftpd/user_list`是白名单文件，此文件中的用户允许访问FTP服务器

`vsftpd.conf`配置文件参数说明如下：

- 用户登录控制参数说明如下表所示

| 参数                   | 说明                      |
| ---------------------- | ------------------------- |
| `anonymous_enable=YES` | 接受匿名用户              |
| `no_anon_password=YES` | 匿名用户login时不询问口令 |
| `anon_root=（none）`   | 匿名用户主目录            |
| `local_enable=YES`     | 接受本地用户              |
| `local_root=（none）`  | 本地用户主目录            |

- 用户权限控制参数说明如下表所示

| 参数                         | 说明                        |
| ---------------------------- | --------------------------- |
| `write_enable=YES`           | 可以上传文件（全局控制）    |
| `local_umask=022`            | 本地用户上传的文件权限      |
| `file_open_mode=0666`        | 上传文件的权限配合umask使用 |
| `anon_upload_enable=NO`      | 匿名用户可以上传文件        |
| `anon_mkdir_write_enable=NO` | 匿名用户可以建目录          |
| `anon_other_write_enable=NO` | 匿名用户修改删除            |
| `chown_username=lightwiter`  | 匿名上传文件所属用户名      |

### 主配置文件

- `anonymous_enable` 是否允许匿名登录服务器
- `local_enable` 是否允许本地用户登录服务器
- `write_enable` 是否允许本地用户具有写权限
- `local_umask` 本地用户的文件掩码
- local_root 系统用户登录路径
- anon_root 匿名用户登录路径
- chroot_local_user 是否锁定用户登录目录为其根目录
- anon_upload_enable 是否允许匿名用户上传文件，须开启 write_enable 选项
- anon_mkdir_write_enable 是否允许匿名用户创建新文件夹
- dirmessage_enable 是否激活目录欢迎信息功能
- xferlog_enable 如果启用此选项，系统将会记录服务器上传和下载的日志文件，默认日志文件为 /var/log/vsftpd.log，也可以通过 xferlog_file 选项设定
- xferlog_file=/var/log/vsftpd.log 服务器上传、下载的日志存储路径
- xferlog_std_format 以 xferlog 格式记录日志文件
- syslog_enable 是否将日志写入系统日志中
- connect_from_port_20=YES 开启主动模式后是否启用默认的 20 端口监听
- chown_uploads 是否允许改变上传文件的属主，与下面选项配合使用
- chown_username 改变上传文件的属主，输入一个系统用户名，whoever：任何人
- idle_session_timeout 数据传输中断间隔时间
- data_connection_timeout 数据连接超时时间
- nopriv_user=ftpsecure 运行 vsftpd 需要的非特权系统用户
- use_localtime 是否使用主机的时间，默认使用 GMT 时间，比北京时间晚 8小时，建议设定为 YES
- ascii_upload_enable 以 ASCII 方式上传数据
- ascii_download_enable 以 ASCII 方式下载数据
- ftpd_banner 登录 FTP 服务器时显示的欢迎信息
- chroot_list_enable 用户是否具有访问自己目录以外文件的权限，设置为 YES 时，用户被锁定在自己的 home 目录中
- chroot_list_file=/etc/vsftpd/chroot_list 不能访问自己目录以外的用户名，需要和 chroot_list_enable 配合使用
- ls_recurse_enable 是否允许递归查询
- listen 是否让 vsftpd 以独立模式运行，由 vsftpd 自己监听和处理连接请求
- listen_ipv6 是否支持 IPV6
- userlist_enable 是否阻止 ftpusers 文件中的用户登录服务器
- userlist_deny 是否阻止 user_list 文件中的用户登录服务器
- tcp_wrappers 是否使用 tcp_wrappers 作为主机访问控制方式
- max_client 允许的最大客户端连接数，0 为不限制
- max_per_ip 同一 IP 允许的最大客户端连接数，0 为不限制
- local_max_rate 本地用户的最大传输速率（单位：B/s），0 为不限制
- anon_max_rate 匿名用户的最大传输速率

## 本地用户模式

```bash
adduser ftptest
passwd ftptest

# 创建一个供 FTP 服务使用的文件目录
mkdir /var/ftp/test
chown -R ftptest:ftptest /var/ftp/test
```

ftp 配置如下

```ini
# 禁止匿名登录FTP服务器
anonymous_enable=NO
# 允许本地用户登录FTP服务器
local_enable=YES
# 监听IPv4 sockets
listen=YES
```

在配置文件的末尾添加下列参数，其中`pasv_address`参数需要替换为 IP 地址：

```ini
# 设置本地用户登录后所在目录
local_root=/var/ftp/test
# 全部用户被限制在主目录
chroot_local_user=YES
# 启用例外用户名单
chroot_list_enable=YES
# 指定例外用户列表文件，列表中用户不被锁定在主目录
chroot_list_file=/etc/vsftpd/chroot_list
# 开启被动模式
pasv_enable=YES
allow_writeable_chroot=YES
# IP地址
pasv_address=39.105.xx.xx
# 设置被动模式下，建立数据传输可使用的端口范围的最小值
# 建议您把端口范围设置在一段比较高的范围内，例如50000~50010，有助于提高访问FTP服务器的安全性
pasv_min_port=50000
# 设置被动模式下，建立数据传输可使用的端口范围的最大值
pasv_max_port=50010
```

创建 chroot_list 文件，并在文件中写入例外用户名单

 ```
 vim /etc/vsftpd/chroot_list
 ```

## 应用示例

### 匿名用户登录最小配置

```ini
# 不以独立模式运行
listen=NO
# 支持 IPV6，如不开启 IPV4 也无法登录
listen_ipv6=YES
# 匿名用户登录
anonymous_enable=YES
# 系统用户登录
local_enable=YES
# 对文件具有写权限，否则无法上传
write_enable=YES
# 允许匿名用户上传文件
anon_upload_enable=YES
# 允许匿名用户新建文件夹
anon_mkdir_write_enable=YES
# 匿名用户删除文件和重命名文件
anon_other_write_enable=YES
# 匿名用户的掩码（022 的实际权限为 666-022=644）
anon_umask=022
# 匿名用户访问路径
anon_root=/var/www/html/web
# 指定端口号
listen_port=5001
# 使用主机时间
use_localtime=YES
pam_service_name=vsftpd
```

由于 vsftpd 增强了安全检查，如果用户被限定在其主目录下，则用户的主目录不能具有写权限，如果还有写权限，就会报该错误：

500 OOPS: vsftpd: refusing to run with writable root inside chroot()

要修复这个错误，可以删除用户的写权限 `chmod a-w /var/www/html/web` 。 或者在 vsftpd 的配置文件中增加下列两项：

```ini
chroot_local_user=YES
allow_writeable_chroot=YES
```

### 设置禁止登录的用户账号

当主配置文件中包括以下设置时，vsftpd.user_list 中的用户账号被禁止登录

```ini
userlist_enable=YES
userlist_deny=YES
userlist_enable=YES
```

userlist_deny 和 userlist_enable 选项限制用户登录服务器，可以有效阻止 root,apache,www 等系统用户登录服务器，从而保证服务器的分级安全性。

```ini
userlist_enable=YES
    ; ftpusers 中用户允许访问，user_list 中用户允许访问

userlist_enable=NO
    ; ftpusers 中用户禁止访问，user_list 中用户允许访问

userlist_deny=YES
    ; ftpusers 中用户禁止访问，user_list 中用户禁止访问

userlist_deny=NO
    ; ftpusers 中用户禁止访问，user_list 中用户允许访问

userlist_deny=YES
userlist_enable=YES
    ; ftpusers 中用户禁止访问，user_list 中用户禁止访问

userlist_deny=NO
userlist_enable=YES
    ; ftpusers 中用户禁止访问，user_list 中用户允许访问
```

### 单向 FTP

一个机器同时拥有 `192.168.52.x` 和 `192.168.53.x` 的 IP，希望通过 52 连接时，只能下载；通过 53 连接时，只能上传

并且为了方便用户使用，需要将账号对接到 AD 域

```bash
# 基本配置
listen=YES
listen_ipv6=NO

# 限制下载和上传目录
anon_root=/srv/ftp

# 用户配置
userlist_enable=YES
userlist_deny=NO
userlist_file=/etc/vsftpd.user_list

# 指定不同网卡配置
seccomp_sandbox=NO

# 下载限制配置 (192.168.52.x)
pasv_address=192.168.52.248
pasv_min_port=30000
pasv_max_port=36000
local_umask=022

# 上传限制配置 (192.168.53.x)
pasv_address=192.168.53.248
pasv_min_port=40000
pasv_max_port=46000
local_umask=077
```



## FTP 数字代码的意义

| 代码 | 意义                                 |
| ---- | ------------------------------------ |
| 110  | 重新启动标记应答                     |
| 120  | 服务在多久时间内 ready               |
| 125  | 数据链路端口开启，准备传送           |
| 150  | 文件状态正常，开启数据连接端口       |
| 200  | 命令执行成功                         |
| 202  | 命令执行失败                         |
| 211  | 系统状态或是系统求助响应             |
| 212  | 目录的状态                           |
| 213  | 文件的状态                           |
| 214  | 求助的讯息                           |
| 215  | 名称系统类型                         |
| 220  | 新的联机服务 ready                   |
| 221  | 服务的控制连接端口关闭，可以注销     |
| 225  | 数据连结开启，但无传输动作           |
| 226  | 关闭数据连接端口，请求的文件操作成功 |
| 227  | 进入 passive mode                    |
| 230  | 使用者登入                           |
| 250  | 请求的文件操作完成                   |
| 257  | 显示目前的路径名称                   |
| 331  | 用户名称正确，需要密码               |
| 332  | 登入时需要账号信息                   |
| 350  | 请求的操作需要进一部的命令           |
| 421  | 无法提供服务，关闭控制连结           |
| 425  | 无法开启数据链路                     |
| 426  | 关闭联机，终止传输                   |
| 450  | 请求的操作未执行                     |
| 451  | 命令终止：有本地的错误               |
| 452  | 未执行命令：磁盘空间不足             |
| 500  | 格式错误，无法识别命令               |
| 501  | 参数语法错误                         |
| 502  | 命令执行失败                         |
| 503  | 命令顺序错误                         |
| 504  | 命令所接的参数不正确                 |
| 530  | 未登入                               |
| 532  | 储存文件需要账户登入                 |
| 550  | 未执行请求的操作                     |
| 551  | 请求的命令终止，类型未知             |
| 552  | 请求的文件终止，储存位溢出           |
| 553  | 未执行请求的的命令，名称不正确       |