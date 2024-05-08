登入时黑屏

- <https://blog.51cto.com/emcome/1891427>

blast 默认使用 TCP 的 8443 端口

文档：<https://docs.vmware.com/cn/VMware-Horizon/2312/virtual-desktops/GUID-4FA4885C-EF55-4472-8B0C-D39BCACFDA84.html>

VMware 间接显卡驱动程序无法与 Hypervisor 直接通信，并且不支持使用 Hypervisor 远程控制台，在 `HKLM\Software\Policies\VMware, Inc.\VMware Blast\Config` 中，配置以下注册表设置：

```
HypervisorConsoleForcedEnabled REG_SZ : 1
```

在低延迟模式下使用 VMware 间接显卡驱动程序，此模式允许以较高的帧速率呈现应用程序，从而减小用户输入延迟。要激活低延迟模式，在 `HKLM\Software\Policies\VMware, Inc.\VMware Blast\Config` 中配置以下注册表设置：

```
PixelProviderLowLatencyEnabled REG_SZ : 1
```

Windows 操作系统自动优化：<https://techzone.omnissa.com/resource/windows-os-optimization-tool-vmware-horizon-guide#_Building_an_Image>>