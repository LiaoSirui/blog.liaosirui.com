查看 coredump 状态

```bash
esxcli system coredump file list
```

如果 ESXi 主机运行过程中出现紫屏，会自动收集 dump 日志信息，类似 linux 系统的 core dump

解析 esxi zdump log 只能在对应的 ESXi 系统上进行解析

```bash
esxcfg-dumppart --copy --devname /vmfs/devices/disks/naa.xxxxx:x --newonly --zdumpname esxdump
esxcfg-dumppart --log ./vmkernel-zdump.1
```

打开解压出来的 vmkernel-log.1 ，搜索 “BlueScreen” 关键字查看死机的原因，以及挂死时的 trace 信息

在 “BlueScreen” 前 ESXi 系统会打印出各个 CPU core 的运行进程和 VM 信息，有助于分析死机前系统的运行状态

由于 VMware ESXi 系统不是开源的，更多的 dump 信息解析需要将日志提交给 VMware 的技术支持才能分析出死机的原因

删除

```bash
esxcli system coredump file remove --force
```

