vscode 出现报错

```bash
Resolver error: Error: Failed to write install script to path
```

因为环境变量 TEMP 被 Python 改变，重新调整回用户 TEMP 目录即可