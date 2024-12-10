PercCLI（PERC Command Line Interface）是戴尔公司的一款命令行实用程序，用于管理戴尔 PowerEdge RAID 控制器

查询最新版本：<https://www.dell.com/support/home/zh-cn/drivers/driversdetails?driverid=f48c2>

安装

```bash
wget https://dl.dell.com/FOLDER04470715M/1/perccli_7.1-007.0127_linux.tar.gz

# 解压后进入 Linux 目录安装
dnf localinstall perccli-007.0127.0000.0000-1.noarch.rpm

ln -s /opt/MegaRAID/perccli/perccli64 /usr/sbin/perccli64
```

磁盘

```bash
perccli /c0 show all
```

参考资料

- <https://www.dell.com/support/manuals/zh-cn/poweredge-rc-h730/perc_cli_rg/working-with-the-perc-command-line-interface-tool?guid=guid-2ac58a14-580a-42cd-8bb6-e710dcdb0cd3&lang=en-us>

