安装

```bash
export INST_TETRAGON_VERSION=v1.1.0
export INST_TETRAGON_ARCH=amd64

wget https://github.com/cilium/tetragon/releases/download/${INST_TETRAGON_VERSION}/tetra-linux-${INST_TETRAGON_ARCH}.tar.gz
wget https://github.com/cilium/tetragon/releases/download/${INST_TETRAGON_VERSION}/tetragon-${INST_TETRAGON_VERSION}-${INST_TETRAGON_ARCH}.tar.gz
```

文档位置：<https://tetragon.io/docs/installation/package/>

默认的 Tetragon 配置随 Tetragon 软件包一起安装在 `/usr/local/lib/tetragon/tetragon.conf.d/` 中。本地管理员可以通过在 `/etc/tetragon/tetragon.conf.d/` 内添加 drop-ins 来覆盖默认设置，或者使用命令行标志进行更改。要恢复默认设置，请删除 `/etc/tetragon/tetragon.conf.d/` 中添加的任何配置

Tracing Policy 的配置默认放在：`/etc/tetragon/tetragon.tp.d/`

获取事件

```bash
tetra --server-address "unix:///var/run/tetragon/tetragon.sock" getevents -o compact --host
```

设置 policy 监听  UDP

```yaml
apiVersion: cilium.io/v1alpha1
kind: TracingPolicy
metadata:
  name: "connect"
spec:
  kprobes:
  - call: "udp_connect"
    syscall: false
    args:
    - index: 0
      type: "sock"
  - call: "udp_close"
    syscall: false
    args:
    - index: 0
      type: "sock"
  - call: "udp_sendmsg"
    syscall: false
    args:
    - index: 0
      type: "sock"
    - index: 2
      type: int
```
