禁止内核自动更新

```bash
# 禁用内核更新
sudo apt-mark hold linux-generic linux-image-generic linux-headers-generic

# 恢复内核更新
sudo apt-mark unhold linux-generic linux-image-generic linux-headers-generic
```

在 unattended-upgrades 配置文件中禁用内核更新

```bash
sudo vi /etc/apt/apt.conf.d/50unattended-upgrades

# 找到 Package-Blacklist 字段，加入如下内容

Unattended-Upgrade::Package-Blacklist {
"linux-generic";
"linux-image-generic";
"linux-headers-generic";
};
```

关闭 Ubuntu 的自动更新

```bash
systemctl disable --now unattended-upgrades
```

