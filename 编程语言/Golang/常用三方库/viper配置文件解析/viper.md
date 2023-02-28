## Viper

Viper 是适用于 Go 应用程序（包括 [Twelve-Factor App](https://12factor.net/zh_cn/)）的完整配置解决方案

它被设计用于在应用程序中工作，并且可以处理所有类型的配置需求和格式

支持以下特性：

- 设置默认值
- 从 `JSON`、`TOML`、`YAML`、`HCL`、`envfile` 和 `Java properties` 格式的配置文件读取配置信息
- 实时监控和重新读取配置文件（可选）
- 从环境变量中读取
- 从远程配置系统（`etcd` 或 `Consul`）读取并监控配置变化
- 从命令行参数读取配置
- 从 `buffer` 读取配置

官方：

- GitHub 仓库：<https://github.com/spf13/viper>
- 文档：<https://github.com/spf13/viper/blob/master/README.md>

## 读取 YAML

新建 app.yaml

```yaml
app:
  name: Gin框架学习实践
  version: v1.0
mysql:
  host: 127.0.0.1
  port: 3306
  user: root
  password: 123456

```

解析 `yaml` 文件



## 读取 TOML

