AppArmor 是一个 Linux 内核安全模块， 它补充了基于标准 Linux 用户和组的权限，将程序限制在一组有限的资源中。 AppArmor 可以配置为任何应用程序减少潜在的攻击面，并且提供更加深入的防御。 它通过调整配置文件进行配置，以允许特定程序或容器所需的访问， 如 Linux 权能字、网络访问、文件权限等。 每个配置文件都可以在 强制（enforcing） 模式（阻止访问不允许的资源）或 投诉（complain） 模式（仅报告冲突）下运行

```bash
cat /sys/module/apparmor/parameters/enabled
Y
```



可供参考的文档：

- <https://kubernetes.io/zh-cn/docs/tutorials/security/apparmor/>