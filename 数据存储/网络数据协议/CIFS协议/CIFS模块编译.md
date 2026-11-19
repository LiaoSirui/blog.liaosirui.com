在不支持 SMB-Direct 功能的情况下重新构建 cifs 模块，从而避免依赖冲突的问题

以下脚本建议还是手动单步执行和确认，没有做容错处理

本文以  Rocky9.6 内核版本 `5.14.0-570.17.1.el9_6.x86_64` 为例，对应 kernele src 下载地址：<https://dl.rockylinux.org/vault/rocky/9.6/AppStream/source/tree/Packages/k/kernel-5.14.0-570.18.1.el9_6.src.rpm>

```bash
#!/usr/bin/env bash
set -euo pipefail

KVER=${1:-$(uname -r)}
KREL=${KVER%.x86_64}
KDIR=/usr/src/kernels/$KVER
SRPM=${SRPM:-kernel-$KREL.src.rpm}
# 可通过环境变量指定"最接近版本"的 SRPM
# SRPM=kernel-5.14.0-570.18.1.el9_6.src.rpm
WORK=/root/cifs-build/$KVER

[ -f "$KDIR/Module.symvers" ] || { echo "缺少 kernel-devel-$KVER"; exit 1; }

# 1. 解出 fs/smb 源码
rm -rf "$WORK"; mkdir -p "$WORK"
rpm2cpio "$SRPM" | (cd "$WORK" && cpio -idm 'linux-*.tar.xz')
tar xf "$WORK"/linux-*.tar.xz -C "$WORK" --strip-components=1 --wildcards '*/fs/smb'

# 2. 关闭 SMB Direct 并编译
cd "$WORK/fs/smb/client"
echo '#undef CONFIG_CIFS_SMB_DIRECT' > no_smbdirect.h
make -C "$KDIR" M="$PWD" \
     CONFIG_CIFS=m CONFIG_CIFS_SMB_DIRECT= \
     KCFLAGS="-include $PWD/no_smbdirect.h" \
     -j"$(nproc)" modules

# 3. 校验
DEPS=$(modinfo -F depends ./cifs.ko)
VMAG=$(modinfo -F vermagic ./cifs.ko | awk '{print $1}')
echo "depends : $DEPS"
echo "vermagic: $VMAG"
echo "$DEPS" | grep -Eq 'ib_core|rdma_cm' && { echo "仍依赖 RDMA,失败"; exit 1; }
[ "$VMAG" = "$KVER" ] || { echo "vermagic 不匹配"; exit 1; }
nm ./cifs.ko | grep -qi ' smbd_' && { echo "残留 smbdirect 代码"; exit 1; }

# 4. 安装
install -D -m 644 cifs.ko /lib/modules/$KVER/updates/fs/smb/client/cifs.ko

# 5. 去掉 OFED 对 cifs 的 override
# 直接编辑文件 /etc/depmod.d/zz01-mlnx-ofa_kernel-cifs.conf
for f in /etc/depmod.d/*; do
  sed -i 's/^\(override[[:space:]]\+cifs[[:space:]].*\)/#\1/' "$f"
done
depmod -a "$KVER"

echo "解析结果: $(modinfo -k "$KVER" -n cifs)"

```

最后重新加载内核模块

```bash
modprobe -r cifs

tee /etc/modules-load.d/cifs.conf << 'EOF'
cifs
cifs_arc4
cifs_md4
EOF

depmod -a $(uname -r)
systemctl restart systemd-modules-load

# 如果 cifs 被打进了 initramfs 需要重建
lsinitrd | grep cifs && dracut -f
```

