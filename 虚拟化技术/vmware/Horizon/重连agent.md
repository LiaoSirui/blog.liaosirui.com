将虚拟机移除网卡后重新添加网卡，Horizon控制台显示无法访问代理

进入连接服务器

```powershell
CD C:\Program Files\VMware\VMware View\Server\tools\bin
```

之后运行

```powershell
vdmadmin -A -d desktop-pool-name -m name-of-machine-in-pool -resetkey
```

