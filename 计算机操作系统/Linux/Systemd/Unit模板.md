## Unit 文件占位符

在 Unit 文件中，有时会需要使用到一些与运行环境有关的信息，例如节点 ID、运行服务的用户等。这些信息可以使用占位符来表示，然后在实际运行被动态地替换实际的值。

- %n：完整的 Unit 文件名字，包括 .service 后缀名
- %p：Unit 模板文件名中 @ 符号之前的部分，不包括 @ 符号
- %i：Unit 模板文件名中 @ 符号之后的部分，不包括 @ 符号和 .service 后缀名
- %t：存放系统运行文件的目录，通常是 “run”
- %u：运行服务的用户，如果 Unit 文件中没有指定，则默认为 root
- %U：运行服务的用户 ID
- %h：运行服务的用户 Home 目录，即 %{HOME} 环境变量的值
- %s：运行服务的用户默认 Shell 类型，即 %{SHELL} 环境变量的值
- %m：实际运行节点的 Machine ID，对于运行位置每个的服务比较有用
- %b：Boot ID，这是一个随机数，每个节点各不相同，并且每次节点重启时都会改变
- %H：实际运行节点的主机名
- %v：内核版本，即 “uname -r” 命令输出的内容
- %%：在 Unit 模板文件中表示一个普通的百分号

## Unit 模板

在现实中，往往有一些应用需要被复制多份运行。例如，用于同一个负载均衡器分流的多个服务实例，或者为每个 SSH 连接建立一个独立的 sshd 服务进程。

Unit 模板文件的写法与普通的服务 Unit 文件基本相同，不过 Unit 模板的文件名是以 @ 符号结尾的。通过模板启动服务实例时，需要在其文件名的 @ 字符后面附加一个参数字符串。

例如 `apache@.service` 模板

```ini
[Unit]
Description=My Advanced Service Template
After=etcd.service docker.service

[Service]
TimeoutStartSec=0
ExecStartPre=-/usr/bin/docker kill apache%i
ExecStartPre=-/usr/bin/docker rm apache%i
ExecStartPre=/usr/bin/docker pull coreos/apache
ExecStart=/usr/bin/docker run --name apache%i -p %i:80 coreos/apache /usr/sbin/apache2ctl -D FOREGROUND
ExecStartPost=/usr/bin/etcdctl set /domains/example.com/%H:%i running
ExecStop=/usr/bin/docker stop apache1
ExecStopPost=/usr/bin/docker rm apache1
ExecStopPost=/usr/bin/etcdctl rm /domains/example.com/%H:%i

[Install]
WantedBy=multi-user.target
```

启动 Unit 模板的服务实例

在服务启动时需要在 @ 后面放置一个用于区分服务实例的附加字符参数，通常这个参数用于监控的端口号或控制台 TTY 编译号

```bash
systemctl start apache@8080.service
```

Systemd 在运行服务时，总是会先尝试找到一个完整匹配的 Unit 文件，如果没有找到，才会尝试选择匹配模板。例如上面的命令，System 首先会在约定的目录下寻找名为 `apache@8080.service` 的文件，如果没有找到，而文件名中包含 @ 字符，它就会尝试去掉后缀参数匹配模板文件。对于 `apache@8080.service`，systemd 会找到 `apache@.service` 模板文件，并通过这个模板文件将服务实例化