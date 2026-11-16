移除 `/etc/ld.so.conf.d/containerd.conf`

清理

```bash
readonly BIN_DIR=/usr/bin

systemctl stop containerd
systemctl disable containerd
rm -rf /etc/containerd
rm -rf /etc/systemd/system/containerd.service
systemctl daemon-reload

rm -rf /var/lib/containerd
rm -rf /run/containerd/containerd.sock
rm -rf /var/lib/nerdctl
rm -f ${BIN_DIR}/containerd
rm -f ${BIN_DIR}/containerd-stress
rm -f ${BIN_DIR}/containerd-shim
rm -f ${BIN_DIR}/containerd-shim-runc-v1
rm -f ${BIN_DIR}/containerd-shim-runc-v2
rm -f ${BIN_DIR}/crictl
rm -f /etc/crictl.yaml
rm -f ${BIN_DIR}/ctr
rm -f ${BIN_DIR}/ctd-decoder
rm -f ${BIN_DIR}/runc
rm -f ${BIN_DIR}/nerdctl
rm -f ${BIN_DIR}/crun
rm -f ${BIN_DIR}/crun_

rm -rf /opt/containerd
rm -rf /etc/ld.so.conf.d/containerd.conf
```

