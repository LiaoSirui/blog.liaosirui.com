
## 安装

配置源

```bash
cat > /etc/yum.repos.d/docker-ce.repo << _EOF_
[docker-ce-stable]
name=Docker CE Stable - $basearch
baseurl=https://mirrors.tuna.tsinghua.edu.cn/docker-ce/linux/centos/$releasever/$basearch/stable
enabled=0
gpgcheck=1
gpgkey=https://mirrors.tuna.tsinghua.edu.cn/docker-ce/linux/centos/gpg

[docker-ce-stable-debuginfo]
name=Docker CE Stable - Debuginfo $basearch
baseurl=https://mirrors.tuna.tsinghua.edu.cn/docker-ce/linux/centos/$releasever/debug-$basearch/stable
enabled=0
gpgcheck=1
gpgkey=https://mirrors.tuna.tsinghua.edu.cn/docker-ce/linux/centos/gpg

[docker-ce-stable-source]
name=Docker CE Stable - Sources
baseurl=https://mirrors.tuna.tsinghua.edu.cn/docker-ce/linux/centos/$releasever/source/stable
enabled=0
gpgcheck=1
gpgkey=https://mirrors.tuna.tsinghua.edu.cn/docker-ce/linux/centos/gpg

[docker-ce-test]
name=Docker CE Test - $basearch
baseurl=https://mirrors.tuna.tsinghua.edu.cn/docker-ce/linux/centos/$releasever/$basearch/test
enabled=0
gpgcheck=1
gpgkey=https://mirrors.tuna.tsinghua.edu.cn/docker-ce/linux/centos/gpg

[docker-ce-test-debuginfo]
name=Docker CE Test - Debuginfo $basearch
baseurl=https://mirrors.tuna.tsinghua.edu.cn/docker-ce/linux/centos/$releasever/debug-$basearch/test
enabled=0
gpgcheck=1
gpgkey=https://mirrors.tuna.tsinghua.edu.cn/docker-ce/linux/centos/gpg

[docker-ce-test-source]
name=Docker CE Test - Sources
baseurl=https://mirrors.tuna.tsinghua.edu.cn/docker-ce/linux/centos/$releasever/source/test
enabled=0
gpgcheck=1
gpgkey=https://mirrors.tuna.tsinghua.edu.cn/docker-ce/linux/centos/gpg

[docker-ce-nightly]
name=Docker CE Nightly - $basearch
baseurl=https://mirrors.tuna.tsinghua.edu.cn/docker-ce/linux/centos/$releasever/$basearch/nightly
enabled=0
gpgcheck=1
gpgkey=https://mirrors.tuna.tsinghua.edu.cn/docker-ce/linux/centos/gpg

[docker-ce-nightly-debuginfo]
name=Docker CE Nightly - Debuginfo $basearch
baseurl=https://mirrors.tuna.tsinghua.edu.cn/docker-ce/linux/centos/$releasever/debug-$basearch/nightly
enabled=0
gpgcheck=1
gpgkey=https://mirrors.tuna.tsinghua.edu.cn/docker-ce/linux/centos/gpg

[docker-ce-nightly-source]
name=Docker CE Nightly - Sources
baseurl=https://mirrors.tuna.tsinghua.edu.cn/docker-ce/linux/centos/$releasever/source/nightly
enabled=0
gpgcheck=1
gpgkey=https://mirrors.tuna.tsinghua.edu.cn/docker-ce/linux/centos/gpg
_EOF_
```

查看可用版本

```bash
yum --disablerepo=\* --enablerepo=docker-ce-stable repolist

yum --disablerepo=\* --enablerepo=docker-ce-stable list available

yum --disablerepo=\* --enablerepo=docker-ce-stable list docker-ce --showduplicates | sort -r
```

例如：

```bash
Loaded plugins: versionlock
Installed Packages
docker-ce.x86_64               3:20.10.14-3.el7                docker-ce-stable
docker-ce.x86_64               3:20.10.14-3.el7                @docker-ce-stable
Available Packages
```

安装对应的版本

```bash
yum install --enablerepo=docker-ce-stable docker-ce-20.10.14-3.el7.x86_64
```

锁版本

```bash
yum versionlock docker-ce
```

可以查看 `/etc/yum/pluginconf.d/versionlock.list` 是否出现对应的锁，例如

```bash
3:docker-ce-20.10.14-3.el7.*
```

## systemd unit 文件

`/usr/lib/systemd/system/docker.service`

- docker 从 1.13 版本开始，将`iptables` 的`filter` 表的`FORWARD` 链的默认策略设置为`DROP`，从而导致 ping 其它 Node 上的 Pod IP 失败，因此必须在 `filter` 表的`FORWARD` 链增加一条默认允许规则 `iptables -I FORWARD -s 0.0.0.0/0 -j ACCEPT`
- 运行 dockerd --help 查看所有可配置参数，确保默认开启 --iptables 和 --ip-masq 选项

```plain
[Unit]
Description=Docker Application Container Engine
Documentation=https://docs.docker.com
After=network-online.target docker.socket firewalld.service containerd.service
Wants=network-online.target
Requires=docker.socket containerd.service

[Service]
Type=notify
# close -H fd://
# ExecStart=/usr/bin/dockerd -H fd:// --containerd=/run/containerd/containerd.sock
ExecStart=/usr/bin/dockerd --containerd=/run/containerd/containerd.sock
# set iptables before start
ExecStartPost=/sbin/iptables -I FORWARD -s 0.0.0.0/0 -j ACCEPT
ExecReload=/bin/kill -s HUP $MAINPID
TimeoutSec=0
# set RestartSec 2 -> 5
RestartSec=5
Restart=always
StartLimitBurst=3
StartLimitInterval=60s
LimitNOFILE=infinity
LimitNPROC=infinity
LimitCORE=infinity
TasksMax=infinity
Delegate=yes
KillMode=process
OOMScoreAdjust=-500

[Install]
WantedBy=multi-user.target
```

## 配置 daemon.json

```jinja
{
  "data-root": "{{ docker.daemon_config.data_root|default("/data/docker") }}",
  "exec-opts": ["native.cgroupdriver={{ docker.daemon_config.cgroup_driver|default("cgroupfs") }}"],
{% if docker.daemon_config.enable_mirror_registry %}
  "registry-mirrors": [
    "https://docker.mirrors.ustc.edu.cn",
    "http://hub-mirror.c.163.com"
  ], 
{% endif %}
{% if docker.daemon_config.enable_remote_api %}
  "hosts": ["tcp://0.0.0.0:2376", "unix:///var/run/docker.sock"],
{% else %}
  "hosts": ["unix:///var/run/docker.sock"],
{% endif %}
  "insecure-registries": {{ docker.daemon_config.insecure_registries|to_json() }},
  "max-concurrent-downloads": 10,
  "live-restore": true,
  "log-driver": "json-file",
  "log-level": "warn",
  "log-opts": {
    "max-size": "10m",
    "max-file": "3"
    },
  "storage-driver": "overlay2"
}

```

- data-root 配置容器数据目录，默认 /var/lib/docker，在集群安装时要规划磁盘空间使用
- registry-mirrors 配置国内镜像仓库加速
- live-restore 可以重启 docker daemon ，而不重启容器
- log-opts 容器日志相关参数，设置单个容器日志超过 10M 则进行回卷，回卷的副本数超过 3 个就进行清理

## 配置代理

```bash
mkdir /etc/systemd/system/docker.service.d
cat > /etc/systemd/system/docker.service.d/http_proxy.conf << EOF
[Service]
Environment="HTTP_PROXY=http://192.168.31.90:7890"
Environment="HTTPS_PROXY=http://192.168.31.90:7890"
Environment="NO_PROXY=192.168.31.0/24,10.3.0.0/16,10.4.0.0/16"
EOF

systemctl daemon-reload
systemctl restart docker
```
