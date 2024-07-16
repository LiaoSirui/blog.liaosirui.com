## Conan 简介

Conan 是一个可以对 C/C++ 进行依赖管理的包管理器

官方：

- GitHub 仓库：<https://github.com/conan-io/conan>

Conan 会在第一次启动时自动配置好默认的 Profile 和 Remote 设置。它的配置以及本地的二进制仓库均存储在用户目录下`~/.conan/`中

另外，当使用 Artifactory 来搭建私有仓库时，需要启用 `general.revisions_enabled = 1`这个开关

## 基本概念

### 软件包

Conan 使用这样的格式来描述一个软件包：`名称/版本@用户/渠道`。其中渠道（Channel）用来描述是稳定版（Stable）还是测试版（Testing）等信息，以 boost 为例，可以看到这样的包名：

```
boost/1.64.0@conan/stable
boost/1.65.1@conan/stable
boost/1.66.0@conan/stable
boost/1.67.0@conan/stable
boost/1.68.0@conan/stable
boost/1.69.0@conan/stable
boost/1.70.0@conan/stable
```

