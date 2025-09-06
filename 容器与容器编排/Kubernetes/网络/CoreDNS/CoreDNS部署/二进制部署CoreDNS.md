## 下载预编译版本

CoreDNS 在 GitHub上面提供了各种版本的预编译包，只需要下载对应的版本即可

- GitHub Release：<https://github.com/coredns/coredns/releases/>

```bash
cd $(mktemp -d)

export INST_COREDNS_VERSION=v1.10.1
export INST_COREDNS_ARCH="amd64"

curl -sL "https://github.com/coredns/coredns/releases/download/${INST_COREDNS_VERSION}/coredns_${INST_COREDNS_VERSION/v/}_linux_${INST_COREDNS_ARCH}.tgz" -o ./coredns_${INST_COREDNS_VERSION/v/}_linux_${INST_COREDNS_ARCH}.tgz

tar zxvf ./coredns_${INST_COREDNS_VERSION/v/}_linux_${INST_COREDNS_ARCH}.tgz -C .

```

## 二进制版本的 CoreDNS

### 命令参数

解压对应的版本后可以得到一个二进制文件，直接执行就可以使用

命令参数如下：

```bash
> ./coredns --help

Usage of ./coredns:
  -alsologtostderr
        log to standard error as well as files
  -conf string
        Corefile to load (default "Corefile")
  -dns.port string
        Default port (default "53")
  -log_backtrace_at value
        when logging hits line file:N, emit a stack trace
  -log_dir string
        If non-empty, write log files in this directory
  -logtostderr
        log to standard error instead of files
  -p string
        Default port (default "53")
  -pidfile string
        Path to write pid file
  -plugins
        List installed plugins
  -quiet
        Quiet mode (no initialization output)
  -stderrthreshold value
        logs at or above this threshold go to stderr
  -v value
        log level for V logs
  -version
        Show version
  -vmodule value
        comma-separated list of pattern=N settings for file-filtered logging
```

### 预置插件

需要注意的是，对于预编译的版本，会内置全部官方认证的插件，也就是官网的插件页面列出来的全部插件

插件页面：<https://coredns.io/plugins/>

```bash
> ./coredns -plugins

Server types:
  dns

Caddyfile loaders:
  flag
  default

Other plugins:
  dns.acl
  dns.any
  dns.auto
  dns.autopath
  dns.azure
  dns.bind
  dns.bufsize
  dns.cache
  dns.cancel
  dns.chaos
  dns.clouddns
  dns.debug
  dns.dns64
  dns.dnssec
  dns.dnstap
  dns.erratic
  dns.errors
  dns.etcd
  dns.file
  dns.forward
  dns.geoip
  dns.grpc
  dns.header
  dns.health
  dns.hosts
  dns.k8s_external
  dns.kubernetes
  dns.loadbalance
  dns.local
  dns.log
  dns.loop
  dns.metadata
  dns.minimal
  dns.nsid
  dns.pprof
  dns.prometheus
  dns.ready
  dns.reload
  dns.rewrite
  dns.root
  dns.route53
  dns.secondary
  dns.sign
  dns.template
  dns.timeouts
  dns.tls
  dns.trace
  dns.transfer
  dns.tsig
  dns.view
  dns.whoami
  on
```

### 运行 CoreDNS

CoreDNS 的运行也非常简单，直接运行二进制文件即可，默认情况下可以添加的参数不多，主要是指定配置文件，指定运行端口和设置 quiet 模式

```bash
> ./coredns          
.:53
CoreDNS-1.10.1
linux/amd64, go1.20, 055b2c3
```

默认情况下会直接监听 53 端口，并且读取和自己在相同目录下的 Corefile 配置文件。但是在这种情况下，虽然 CoreDNS 正常运行了，但是由于没有配置文件，是无法正常解析任何域名请求的

```bash
# 直接运行 CoreDNS 让其监听 30053 端口
> ./coredns -dns.port 30053
.:30053
CoreDNS-1.10.1
linux/amd64, go1.20, 055b2c3

# 使用 dig 命令进行测试，发现能够正常返回请求但是解析的结果不正确
> dig liaosirui.com @127.0.0.1 -p30053

; <<>> DiG 9.16.23-RH <<>> liaosirui.com @127.0.0.1 -p30053
;; global options: +cmd
;; Got answer:
;; ->>HEADER<<- opcode: QUERY, status: NOERROR, id: 50013
;; flags: qr aa rd; QUERY: 1, ANSWER: 0, AUTHORITY: 0, ADDITIONAL: 3
;; WARNING: recursion requested but not available

;; OPT PSEUDOSECTION:
; EDNS: version: 0, flags:; udp: 4096
; COOKIE: b403f0f5bf300a52 (echoed)
;; QUESTION SECTION:
;liaosirui.com.                 IN      A

;; ADDITIONAL SECTION:
liaosirui.com.          0       IN      A       127.0.0.1
_udp.liaosirui.com.     0       IN      SRV     0 0 46871 .

;; Query time: 0 msec
;; SERVER: 127.0.0.1#30053(127.0.0.1)
;; WHEN: Tue May 09 12:50:15 CST 2023
;; MSG SIZE  rcvd: 120
```

这里简单编写一个 Corefile 配置文件就能够先让 CoreDNS 正常解析域名，这个配置文件的意识是对所有域的请求都 forward 到 114DNS 进行解析，并且记录正常的日志和错误的日志

```bash
> cat << __EOF__ >> Corefile
. {
    forward . 114.114.114.114 223.5.5.5
    log
    errors
    whoami
}
__EOF__
```

再进行测试就发现 CoreDNS 可以正常解析域名了

```bash
> dig liaosirui.com @127.0.0.1 -p30053

; <<>> DiG 9.16.23-RH <<>> liaosirui.com @127.0.0.1 -p30053
;; global options: +cmd
;; Got answer:
;; ->>HEADER<<- opcode: QUERY, status: NOERROR, id: 4903
;; flags: qr rd ra; QUERY: 1, ANSWER: 1, AUTHORITY: 0, ADDITIONAL: 1

;; OPT PSEUDOSECTION:
; EDNS: version: 0, flags:; udp: 4096
; COOKIE: ee403bdbc862f535 (echoed)
;; QUESTION SECTION:
;liaosirui.com.                 IN      A

;; ANSWER SECTION:
liaosirui.com.          600     IN      A       47.108.210.208

;; Query time: 169 msec
;; SERVER: 127.0.0.1#30053(127.0.0.1)
;; WHEN: Tue May 09 12:52:08 CST 2023
;; MSG SIZE  rcvd: 83
```

## systemd 管理服务

coredns 作为一个二进制执行文件，并没有向其他的如 nginx、bind 等服务提供种类繁多的进程控制（reload stop restart 等等）选项，因此为了方便我们管理和在后台一直运行 coredns，这里我们使用 systemd 对其进行管理，只需要编写一个 systemd 的 unit 文件即可：`/usr/lib/systemd/system/coredns.service`

```ini
[Unit]
Description=CoreDNS
Documentation=https://coredns.io/manual/toc/
After=network.target

[Service]
# Type 设置为 notify 时，服务会不断重启
# 关于 type 的设置，可以参考https://www.freedesktop.org/software/systemd/man/systemd.service.html#Options
Type=simple
User=root
# 指定运行端口和读取的配置文件
ExecStart=/home/coredns/coredns -dns.port=53 -conf /home/coredns/Corefile
Restart=on-failure

[Install]
WantedBy=multi-user.target

```

编写完成之后依次 reload 配置文件并且设置开机启动服务和开启服务

```bash
systemctl daemon-reload

systemctl enable --now coredns.service
```

即可看到服务正常运行

```bash
systemctl status coredns.service
```

### CoreDNS 日志处理

- StandardOutput

CoreDNS 的日志输出并不如 nginx 那么完善（并不能在配置文件中指定输出的文件目录，但是可以指定日志的格式），默认情况下不论是 log 插件还是 error 插件都会把所有的相关日志输出到程序的 standard output 中。使用 systemd 来管理 coredns 之后，默认情况下基本就是由 rsyslog 和 systemd-journald 这两个服务来管理日志

较新版本的 systemd 是可以直接在 systemd 的 unit 文件里面配置 StandardOutput 和 StandardError 两个参数来将相关运行日志输出到指定的文件中

因此对于 centos8 等较新的系统，unit 文件可以这样编写：

```ini
[Unit]
Description=CoreDNS
Documentation=https://coredns.io/manual/toc/
After=network.target
# StartLimit 这两个相关参数也是 centos8 等 systemd 版本较新的系统才支持的
StartLimitBurst=1
StartLimitIntervalSec=15s

[Service]
# Type 设置为 notify 时，服务会不断重启
# 关于 type 的设置，可以参考https://www.freedesktop.org/software/systemd/man/systemd.service.html#Options
Type=simple
User=root
# 指定运行端口和读取的配置文件
ExecStart=/home/coredns/coredns -dns.port=53 -conf /home/coredns/Corefile
Restart=on-failure
# append 类型可以在原有文件末尾继续追加内容，而 file 类型则是重新打开一个新文件
# 两者的区别类似于 >> 和 >
StandardOutput=append:/home/coredns/logs/coredns.log
StandardError=append:/home/coredns/logs/coredns_error.log
Restart=on-failure

[Install]
WantedBy=multi-user.target

```

- rsyslog

对于 centos7 等系统而言，是不支持上面的 append 和 file 两个参数的，那么在开启了 `rsyslog.service` 服务的情况下，日志就会输出到 `/var/log/messages` 文件中，或者可以使用 `journalctl -u coredns` 命令来查看全部的日志。

如果想要将 coredns 的日志全部集中到一个文件进行统一管理，可以对负责管理 `systemd` 的日志的 `rsyslog` 服务的配置进行修改：

```bash
# vim /etc/rsyslog.conf
if $programname == 'coredns' then /home/coredns/logs/coredns.log
& stop

```

然后重启 rsyslog

```bash
systemctl restart rsyslog.service
```

