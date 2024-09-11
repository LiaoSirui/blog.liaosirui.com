## 安装

Windows Exporter 在发布的是时候提供了两种格式的文件，分别是 `*.exe` 和 `*.msi` 

MSI （Microsoft Installers）是 Windows 的包管理器，类似于 Linux 的 rpm 

Windows Exporter 每个版本都提供一个 `.msi` 安装程序。安装程序将 `windows_exporter` 设置为 Windows 服务

使用 MSI 不进行任何参数的指定的时候，他会安装在 `C:\Program Files\windows_exporter\`，启动参数是 `C:\Program Files\windows_exporter\windows_exporter.exe" --log.format logger:eventlog?name=windows_exporter --telemetry.addr :9182`

对于 Windows ，不建议这样部署。建议的部署方式是通过 msiexec 将参数发送到安装程序，比如像下边这样

```bash
msiexec /i <path-to-msi-file> ENABLED_COLLECTORS=cpu,cpu_info,logon,memory,net,service,terminal_services,os,process,vmware_blast,vmware LISTEN_PORT=5000
```

## 采集的指标

这个列表是 Windows Exporter 支持采集的指标，有一些指标是启动后缺省会打开的，有一些是需要手动打开的。 <https://github.com/prometheus-community/windows_exporter#>

默认情况下，windows_exporter 将暴露所有已采集的指标。这是收集指标的推荐方法，以避免在比较不同系列指标时出现错误

## 参考文档

- <https://help.aliyun.com/zh/arms/prometheus-monitoring/how-do-i-install-and-configure-windows-exporter>
- <https://help.aliyun.com/zh/arms/prometheus-monitoring/use-prometheus-to-monitor-windows-oss?spm=a2c4g.11186623.0.i4#task-2270946>

