查看在亚洲 S 开头的上海可用时区

```java
timedatectl list-timezones |  grep  -E "Asia/S.*"
```

设置当前系统为上海时区

```java
timedatectl set-timezone "Asia/Shanghai"
```