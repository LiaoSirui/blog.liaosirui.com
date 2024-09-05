## 挂载目录非空

```bash
Running constructor lxcfs_init to reload liblxcfs
mount namespace: 4
hierarchies:
0: fd: 5: name=systemd
1: fd: 6: perf_event
2: fd: 7: cpu,cpuacct
3: fd: 8: pids
4: fd: 9: blkio
5: fd: 10: net_cls,net_prio
6: fd: 11: memory
7: fd: 12: cpuset
8: fd: 13: freezer
9: fd: 14: rdma
10: fd: 15: hugetlb
11: fd: 16: devices
Kernel supports swap accounting
api_extensions:
- cgroups
- sys_cpu_online
- proc_cpuinfo
- proc_diskstats
- proc_loadavg
- proc_meminfo
- proc_stat
- proc_swaps
- proc_uptime
- proc_slabinfo
- shared_pidns
- cpuview_daemon
- loadavg_daemon
- pidfds
fuse: mountpoint is not empty
fuse: if you are sure this is safe, use the 'nonempty' mount option
Running destructor lxcfs_exit
```

增加挂载参数

```bash
-o allow_other,nonempty
```

