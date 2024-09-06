## 安装 ClamAV

Clam AntiVirus（ClamAV）是免费而且开放源代码的防毒软件，软件与病毒码的更新皆由社群免费发布。ClamAV在命令行下运行，它不将杀毒作为主要功能，默认只能查出系统内的病毒，但是无法清除。需要用户自行对病毒文件进行处理

下载：<https://www.clamav.net/downloads>

```
dnf install -y https://www.clamav.net/downloads/production/clamav-1.3.1.linux.x86_64.rpm
```

默认将安装在 `/usr/local` 中，其中包含：

- 应用程序：`/usr/local/bin`
- 守护进程：`/usr/local/sbin`
- 库文件：`/usr/local/lib`
- 头文件：`/usr/local/include`
- 配置文件：`/usr/local/etc/`
- 病毒库：`/usr/local/share/clamav/`

## 配置 ClamAV

## freshclam.conf

`freshclam` 是自动更新病毒库的工具。它可以配置为在两种模式下工作：

- 交互式 - 从命令行按需执行
- 守护进程 - 静默在后台自动执行

安装后初始化

```
cp -a /usr/local/etc/freshclam.conf.sample /usr/local/etc/freshclam.conf
sed -i 's/^Example/#Example/g' /usr/local/etc/freshclam.conf
```

编辑 `/usr/local/etc/freshclam.conf`，添加以下内容

```
UpdateLogFile /var/log/freshclam.log
LogTime yes
DatabaseOwner root
```

参数说明

- UpdateLogFile：指定更新日志文件
- LogTime：配置日志文件显示时间戳
- DatabaseOwner：指定病毒库文件所属用户

更多配置参数可执行 `man freshclam.conf` 进行查询

创建日志文件

```
touch /var/log/freshclam.log
chmod 600 /var/log/freshclam.log
```

更新病毒库

```
freshclam
```

### clamd.conf

目前，`ClamAV` 要求先配置 `clamd.conf` 文件，然后才可以运行守护进程，至少需要注释掉 “Example” 行，否则 clamd 将认为配置无效。

根据示例配置文件创建 `clamd.conf` 文件

```
cp -a /usr/local/etc/clamd.conf.sample /usr/local/etc/clamd.conf
sed -i 's/^Example/#Example/g' /usr/local/etc/clamd.conf
```

编辑 `/usr/local/etc/clamd.conf`，添加以下内容

```
LogFile /var/log/clamd.log
LogTime yes
LocalSocket /run/clamav/clamd.sock
LocalSocketMode 660
User root
```

参数说明

- LogFile：指定 clamd 日志文件
- LogTime：配置日志文件显示时间戳
- LocalSocket：指定 socket 文件路径
- LocalSocketMode：指定 socket 文件权限
- User：设置运行 clamd 的用户身份

更多配置参数可执行 `man clamd.conf` 进行查询

## 扫描

### ClamD

`ClamD` 是一个多线程守护程序，它使用 `libclamav` 扫描文件以查找病毒。通过修改 `clamd.conf` 可以配置扫描行为以满足大多数需求。

启动 `ClamD`

```
clamd
```

实际测试 clamd 需要占用 2GiB 左右的内存，启动前请确保有足够的内存资源

### ClamDScan

`ClamDScan` 是一个 `ClamD` 客户端，它大大简化了使用 `Clamd` 扫描文件的任务。它通过 `clamd.conf` 中指定的套接字向 `clamd` 守护进程发送命令，并在守护进程完成所有请求的扫描后生成扫描报告。

因此在运行 `ClamDScan` 之前，必须先运行一个 `ClamD` 实例

```
# 全盘扫描，首次扫描时间会比较长
clamdscan /

# clamdscan --log=/var/log/clamdscan.log --config-file=/usr/local/etc/clamd.conf -w /
```

### clamscan

使用 clamscan 命令行对某一目录进行扫描，可以确认结果是否 OK，同时会给出一个扫描的总体信息，其中 Infected files 是扫描出来的被感染的文件个数。比如如下示例表明对 `/root` 目录下的文件进行扫描，未发现感染文件的情况

```
clamscan /root
```

使用 `–-remove` 选项，会直接删除检测出来的文件

```
clamscan --remove /root
```



