## Falco 简介

Falco 是一个云原生运行时安全工具，旨在检测应用程序中的异常活动，可用于监控 Kubernetes 应用程序和内部组件的运行时安全性

仅需为 Falco 撰写一套规则，即可持续监测并监控容器、应用、主机及网络的异常活动

官方：

- 官网：<https://falco.org/>
- 文档：<https://falco.org/docs/>

- GitHub 仓库：<https://github.com/falcosecurity/falco>

Falco 可对任何涉及 Linux 系统调用的行为进行检测和报警。Falco 的警报可以通过使用特定的系统调用、参数以及调用进程的属性来触发。例如，Falco 可以轻松检测到包括但不限于以下事件：

- Kubernetes 中的容器或 pod 内正在运行一个 shell 
- 容器以特权模式运行，或从主机挂载敏感路径，如 `/proc`
- 一个服务器进程正在生成一个意外类型的子进程
- 意外读取一个敏感文件，如 `/etc/shadow`
- 一个非设备文件被写到 `/dev`
- 一个标准的系统二进制文件，如 ls，正在进行一个外向的网络连接
- 在 Kubernetes 集群中启动一个有特权的 Pod