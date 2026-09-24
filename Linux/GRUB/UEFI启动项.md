终端运行：`efibootmgr` 查看所有启动项。

找到不需要的引导项编号（如 `Boot0001`），将其删除：

```bash
efibootmgr -b 0001 -B
```

