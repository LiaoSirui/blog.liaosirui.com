对于二进制部署的 BeeGFS，均使用 systemd 管理进程

- mgmtd

```bash
> /etc/systemd/system/beegfs-mgmtd.service.d/override.conf

[Service]
Nice=-20
IOSchedulingClass=realtime
IOSchedulingPriority=0

```

- meta

```bash
> /etc/systemd/system/beegfs-meta.service.d/override.conf

[Service]
Nice=-20
IOSchedulingClass=realtime
IOSchedulingPriority=0

```

- storage

```bash
> /etc/systemd/system/beegfs-storage.service.d/override.conf

[Service]
Nice=-20
IOSchedulingClass=realtime
IOSchedulingPriority=0

```

- helperd

```bash
> /etc/systemd/system/beegfs-helperd.service.d/override.conf

[Service]
Nice=-20
IOSchedulingClass=realtime
IOSchedulingPriority=0

```

验证 nice 设置的方式（PRI 字段）

```bash
> ps -l -p $(pgrep beegfs-mgmtd)
F S   UID     PID    PPID  C PRI  NI ADDR SZ WCHAN  TTY          TIME CMD
4 S     0   24692       1  0  60 -20 - 196818 hrtime ?       00:15:02 beegfs-mgmtd/Ma

> ps -l -p $(pgrep beegfs-meta)
F S   UID     PID    PPID  C PRI  NI ADDR SZ WCHAN  TTY          TIME CMD
4 S     0   51755       1 13  60 -20 - 1675347 futex_ ?      2-17:02:41 beegfs-meta/Mai

> ps -l -p $(pgrep beegfs-storage)
F S   UID     PID    PPID  C PRI  NI ADDR SZ WCHAN  TTY          TIME CMD
4 S     0   37857       1  5  60 -20 - 682783 futex_ ?       1-01:23:35 beegfs-storage/

> ps -l -p $(pgrep beegfs-helperd)
F S   UID     PID    PPID  C PRI  NI ADDR SZ WCHAN  TTY          TIME CMD
4 S     0    1187       1  0  60 -20 - 76970 futex_ ?        00:00:13 beegfs-helperd/

```

验证 ionice 设置的方式

```bash
> ionice -p $(pgrep beegfs-mgmtd)
realtime: prio 0

> ionice -p $(pgrep beegfs-meta)
realtime: prio 0

> ionice -p $(pgrep beegfs-storage)
realtime: prio 0

> ionice -p $(pgrep beegfs-helperd)
realtime: prio 0

```

