vim-cmd 是每个 ESXi 主机上可用的 CLI 工具，可用于在 VMware 环境中执行各种活动

- 列出注册的虚拟机

```bash
vim-cmd vmsvc/getallvms
```

- 取消注册虚拟机

```bash
vim-cmd vmsvc/unregistervm vmid
```

- 注册虚拟机

```bash
vim-cmd solo/registervm /vmfs/volumes/iSCSI-1/TestDSL/TestDSL.vmx
```

- 查询虚拟机电源状态

```bash
vim-cmd vmsvc/power.getstate 12
```

- 强制关闭虚拟机

```bash
vim-cmd vmsvc/power.shutdown 12
```

- 关闭、打开、重启虚拟机操作系统

```bash
# 关闭虚拟机
vim-cmd vmsvc/power.off 3

# 打开虚拟机
vim-cmd vmsvc/power.on 3

# 重启虚拟机
vim-cmd vmsvc/power.reset 3
```

- 暂停虚拟机

```bash
vim-cmd vmsvc/power.suspend 12
```

- 创建虚拟机快照

```bash
vim-cmd vmsvc/snapshot.create 12 Test_Snapshot
```

