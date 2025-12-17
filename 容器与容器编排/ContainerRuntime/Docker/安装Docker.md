## 二进制安装 docker

参考官网文档： <https://docs.docker.com/engine/install/binaries/#install-daemon-and-client-binaries-on-linux>

下载 docker 二进制版本，请选择最新最稳定的CE版本

<https://download.docker.com/linux/static/stable/x86_64/>

```bash
export DOCKER_VERSION=v24.0.7

cd $(mktemp -d)

wget https://download.docker.com/linux/static/stable/x86_64/docker-${DOCKER_VERSION/v/}.tgz -O docker-ce.tgz

tar zxvf docker-ce.tgz -C .
```

移动所需二进制文件，建立软链

```bash
mv ./docker /usr/local/docker-${DOCKER_VERSION/v/}

ln -s /usr/local/docker-${DOCKER_VERSION/v/}/dockerd /usr/bin/dockerd
ln -s /usr/local/docker-${DOCKER_VERSION/v/}/docker-proxy /usr/bin/docker-proxy
ln -s /usr/local/docker-${DOCKER_VERSION/v/}/docker /usr/bin/docker
ln -s /usr/local/docker-${DOCKER_VERSION/v/}/docker-init /usr/bin/docker-init

ln -s /usr/local/docker-${DOCKER_VERSION/v/}/dockerd /usr/local/bin/dockerd
ln -s /usr/local/docker-${DOCKER_VERSION/v/}/docker-proxy /usr/local/bin/docker-proxy
ln -s /usr/local/docker-${DOCKER_VERSION/v/}/docker /usr/local/bin/docker
ln -s /usr/local/docker-${DOCKER_VERSION/v/}/docker-init /usr/local/bin/docker-init

```

查看二进制和软链

```bash
ls -al /usr/local/docker-${DOCKER_VERSION/v/}
ls -al /usr/bin/docker*
ls -al /usr/local/bin/docker*
```

创建一个 system 管理文件，参考

- <https://github.com/moby/moby/blob/v24.0.7/contrib/init/systemd/docker.service>

```bash
wget https://raw.githubusercontent.com/moby/moby/${DOCKER_VERSION}/contrib/init/systemd/docker.service \
  -O /usr/lib/systemd/system/docker.service
```

配置文件内容如下：

```ini
[Unit]
Description=Docker Application Container Engine
Documentation=https://docs.docker.com
After=network-online.target docker.socket firewalld.service containerd.service time-set.target
Wants=network-online.target containerd.service
Requires=docker.socket

[Service]
Type=notify
# the default is not to use systemd for cgroups because the delegate issues still
# exists and systemd currently does not support the cgroup feature set required
# for containers run by docker
ExecStart=/usr/bin/dockerd -H fd:// --containerd=/run/containerd/containerd.sock
ExecReload=/bin/kill -s HUP $MAINPID
TimeoutStartSec=0
RestartSec=2
Restart=always

# Note that StartLimit* options were moved from "Service" to "Unit" in systemd 229.
# Both the old, and new location are accepted by systemd 229 and up, so using the old location
# to make them work for either version of systemd.
StartLimitBurst=3

# Note that StartLimitInterval was renamed to StartLimitIntervalSec in systemd 230.
# Both the old, and new name are accepted by systemd 230 and up, so using the old name to make
# this option work for either version of systemd.
StartLimitInterval=60s

# Having non-zero Limit*s causes performance problems due to accounting overhead
# in the kernel. We recommend using cgroups to do container-local accounting.
LimitNOFILE=infinity
LimitNPROC=infinity
LimitCORE=infinity

# Comment TasksMax if your systemd version does not support it.
# Only systemd 226 and above support this option.
TasksMax=infinity

# set delegate yes so that systemd does not reset the cgroups of docker containers
Delegate=yes

# kill only the docker process, not all processes in the cgroup
KillMode=process
OOMScoreAdjust=-500

[Install]
WantedBy=multi-user.target
```

注意将 LimitNOFILE 改为 65535

```ini
# LimitNOFILE=infinity
LimitNOFILE=65535
```

创建 docker.socket，参考

- <https://github.com/moby/moby/blob/v23.0.4/contrib/init/systemd/docker.socket>

```bash
wget https://raw.githubusercontent.com/moby/moby/${DOCKER_VERSION}/contrib/init/systemd/docker.socket \
  -O /usr/lib/systemd/system/docker.socket
```

内容如下：

```bash
[Unit]
Description=Docker Socket for the API

[Socket]
# If /var/run is not implemented as a symlink to /run, you may need to
# specify ListenStream=/var/run/docker.sock instead.
ListenStream=/run/docker.sock
SocketMode=0660
SocketUser=root
SocketGroup=docker

[Install]
WantedBy=sockets.target
```

把上面的 group 改为 root

配置 docker 服务端

```bash
mkdir -p /etc/docker
vim /etc/docker/daemon.json 
```

内容如下：

```bash
{
    "debug": false,
    "insecure-registries": [
      "0.0.0.0/0"
    ],
    "ip-forward": true,
    "ipv6": false,
    "live-restore": true,
    "log-driver": "json-file",
    "log-level": "warn",
    "log-opts": {
      "max-size": "100m",
      "max-file": "2"
    },
    "selinux-enabled": false,
    "metrics-addr" : "0.0.0.0:9323",
    "experimental" : true,
    "storage-driver": "overlay2"
}
```

重启进程

```bash
systemctl daemon-reload
systemctl enable --now docker.service
```

配置代理

```bash
mkdir /etc/systemd/system/docker.service.d

cat > /etc/systemd/system/docker.service.d/http_proxy.conf << __EOF__
[Service]
Environment="HTTP_PROXY=http://proxy.local.liaosirui.com:8899"
Environment="HTTPS_PROXY=http://proxy.local.liaosirui.com:8899"
Environment="ALL_PROXY=socks5://proxy.local.liaosirui.com:8899"
Environment="NO_PROXY=127.0.0.1,localhost,10.0.0.0/8,172.16.0.0/12,192.168.0.0/16,.liaosirui.com"
__EOF__

systemctl daemon-reload
systemctl restart docker
```

## 源安装 docker

配置源

```bash
dnf -y install dnf-plugins-core
dnf config-manager --add-repo https://download.docker.com/linux/rhel/docker-ce.repo
```

查看可用版本

```bash
dnf --disablerepo=\* --enablerepo=docker-ce-stable repolist

dnf --disablerepo=\* --enablerepo=docker-ce-stable list available

dnf --disablerepo=\* --enablerepo=docker-ce-stable list docker-ce --showduplicates | sort -r
```

例如：

```bash
Last metadata expiration check: 0:00:27 ago on Thu 20 Jul 2023 01:11:42 AM CST.
docker-ce.x86_64                3:24.0.4-1.el9                  docker-ce-stable
docker-ce.x86_64                3:24.0.3-1.el9                  docker-ce-stable
docker-ce.x86_64                3:24.0.2-1.el9                  docker-ce-stable
docker-ce.x86_64                3:24.0.1-1.el9                  docker-ce-stable
docker-ce.x86_64                3:24.0.0-1.el9                  docker-ce-stable
docker-ce.x86_64                3:23.0.6-1.el9                  docker-ce-stable
docker-ce.x86_64                3:23.0.5-1.el9                  docker-ce-stable
docker-ce.x86_64                3:23.0.4-1.el9                  docker-ce-stable
docker-ce.x86_64                3:23.0.2-1.el9                  docker-ce-stable
docker-ce.x86_64                3:23.0.1-1.el9                  docker-ce-stable
docker-ce.x86_64                3:23.0.0-1.el9                  docker-ce-stable
docker-ce.x86_64                3:20.10.24-3.el9                docker-ce-stable
docker-ce.x86_64                3:20.10.23-3.el9                docker-ce-stable
docker-ce.x86_64                3:20.10.22-3.el9                docker-ce-stable
docker-ce.x86_64                3:20.10.21-3.el9                docker-ce-stable
docker-ce.x86_64                3:20.10.20-3.el9                docker-ce-stable
docker-ce.x86_64                3:20.10.19-3.el9                docker-ce-stable
docker-ce.x86_64                3:20.10.18-3.el9                docker-ce-stable
docker-ce.x86_64                3:20.10.17-3.el9                docker-ce-stable
docker-ce.x86_64                3:20.10.16-3.el9                docker-ce-stable
docker-ce.x86_64                3:20.10.15-3.el9                docker-ce-stable
Available Packages
```

安装对应的版本

```bash
dnf install --enablerepo=docker-ce-stable docker-ce-24.0.4-1.el9.x86_64
```

锁版本

```bash
dnf versionlock docker-ce
```

可以查看 `/etc/yum/pluginconf.d/versionlock.list` 是否出现对应的锁，例如

```bash
3:docker-ce-20.10.14-3.el7.*
```

推荐安装

```bash
dnf install -y docker-ce docker-compose-plugin docker-buildx-plugin
```

配置 `/etc/docker/daemon.json` 如下

```bash
cat <<EOF >/etc/docker/daemon.json
{
    "debug": false,
    "insecure-registries": [
      "0.0.0.0/0"
    ],
    "ip-forward": true,
    "ipv6": false,
    "live-restore": true,
    "log-driver": "json-file",
    "log-level": "warn",
    "log-opts": {
      "max-size": "100m",
      "max-file": "2"
    },
    "selinux-enabled": false,
    "metrics-addr" : "0.0.0.0:9323",
    "experimental" : true,
    "storage-driver": "overlay2"
}
EOF
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
