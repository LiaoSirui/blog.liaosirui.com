vSphere Replication（REP）

不同于虚拟机备份，REP最好的情况下，只会丢失5分钟数据，而且可以保留多达25个数据还原点，可以补充每日备份的缺失；成本低的原因，是**无需额外的许可**，只要有一块作为目标的存储空间，比如就是简单在一个服务器中安装一些3.5寸的大容量磁盘，通过网络，就可以实现更高级别的数据保护

- <https://docs.vmware.com/cn/vSphere-Replication/8.7/com.vmware.vsphere.replication-admin.doc/GUID-C521A814-91E1-4092-BD29-7E2BA256E67E.html>

![您可以在单个 vCenter Server 中复制虚拟机。](./.assets/REP/GUID-FD0A7EBA-AEB7-47C5-8C41-A1D4C9FE0926-high.png)