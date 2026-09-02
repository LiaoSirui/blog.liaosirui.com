（1）最小示例：替换 containerd

```dockerfile
FROM scratch

LABEL sealos.io.type="patch"
COPY containerd /bin/containerd
COPY containerd-shim-runc-v2 /bin/containerd-shim-runc-v2
CMD ["bash", "-c", "cp -f bin/containerd /usr/bin/ && cp -f bin/containerd-shim-runc-v2 /usr/bin/ && systemctl restart containerd"]
```

（2）脚本示例：sysctl 调优

```
.
├── Kubefile
└── scripts/
    └── tune-kernel.sh
```

`scripts/tune-kernel.sh`：

```bash
#!/bin/bash
set -e
cat >> /etc/sysctl.d/99-sealos-patch.conf <<'SYSCTL'
net.core.somaxconn = 65535
net.ipv4.tcp_max_syn_backlog = 65535
vm.max_map_count = 262144
SYSCTL
sysctl --system
```

`Kubefile`：

```dockerfile
FROM scratch
LABEL sealos.io.type="patch"
COPY scripts/ scripts/
CMD ["bash", "scripts/tune-kernel.sh"]
```