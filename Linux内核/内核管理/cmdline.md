调试 systemd 启动失败，增加：

```bash
systemd.log_level=debug systemd.log_target=console console=tty0 console=ttyS0,115200n81
```

