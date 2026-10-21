指定日志级别

参考 <https://github.com/devsu/docker-keycloak/blob/master/server/README.md#specify-log-level>

有两个环境变量可用于控制 Keycloak 的日志级别：

- KEYCLOAK_LOGLEVEL: 为 Keycloak 指定日志级别（可选，默认为 INFO）
- ROOT_LOGLEVEL: 指定底层容器的日志级别（可选，默认为 INFO）

支持的日志级别 ALL，DEBUG，ERROR，FATAL，INFO，OFF，TRACE 和 WARN。

日志级别也可以在运行时更改，例如（假设 docker exec 访问）：

```bash
./keycloak/bin/jboss-cli.sh --connect --command='/subsystem=logging/console-handler=CONSOLE:change-log-level(level=DEBUG)'

./keycloak/bin/jboss-cli.sh --connect --command='/subsystem=logging/root-logger=ROOT:change-root-log-level(level=DEBUG)'

./keycloak/bin/jboss-cli.sh --connect --command='/subsystem=logging/logger=org.keycloak:write-attribute(name=level,value=DEBUG)'
```
