查看在亚洲 S 开头的上海可用时区

```bash
timedatectl list-timezones |  grep  -E "Asia/S.*"
```

设置当前系统为上海时区

```bash
timedatectl set-timezone "Asia/Shanghai"
```
