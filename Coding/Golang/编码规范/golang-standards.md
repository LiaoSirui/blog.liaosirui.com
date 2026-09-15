## 完整布局

参考：<https://github.com/golang-standards/project-layout>

```plain
> tree -F  -I "README*" --dirsfirst
.
├── api/
├── assets/
├── build/
│   ├── ci/
│   └── package/
├── cmd/
│   └── _your_app_/
├── configs/
├── deployments/
├── docs/
├── examples/
├── githooks/
├── init/
├── internal/
│   ├── app/
│   │   └── _your_app_/
│   └── pkg/
│       └── _your_private_lib_/
├── pkg/
│   └── _your_public_lib_/
├── scripts/
├── test/
├── third_party/
├── tools/
├── vendor/
├── web/
│   ├── app/
│   ├── static/
│   └── template/
├── website/
├── go.mod
├── LICENSE.md
└── Makefile
```

## Go 目录

### `cmd` 目录

每个应用程序的目录名应该与你想要的可执行文件的名称相匹配（例如，`/cmd/myapp`）

参考：<https://github.com/golang-standards/project-layout/blob/master/cmd/README.md>

例子：<https://github.com/vmware-tanzu/velero/tree/main/cmd>

```bash
> tree cmd                 
cmd
├── velero
│   └── velero.go
└── velero-restore-helper
    └── velero-restore-helper.go

```

### `internal` 目录

私有应用程序和库代码，这是不希望其他人在其应用程序或库中导入代码

实际应用程序代码可以放在 `/internal/app` 目录下（例如 `/internal/app/myapp`），这些应用程序共享的代码可以放在 `/internal/pkg` 目录下（例如 `/internal/pkg/myprivlib`）

参考：<https://github.com/golang-standards/project-layout/tree/master/internal/README.md>

例子：<https://github.com/hashicorp/terraform/tree/main/internal>

```bash
> tree internal -d
internal
├── addrs
├── backend
│   ├── init
│   ├── local
│   ├── remote
```

### `pkg` 目录

外部应用程序可以使用的库代码

参考：<https://github.com/golang-standards/project-layout/blob/master/pkg/README.md>

例子：<https://github.com/istio/istio/tree/master/pkg>

命名推荐表：

- admin : 站点管理
- auth : 用户验证
- comments : 评论
- csrf : 防御跨站请求伪造（CSRF）
- databrowse：浏览数据
- formtools : 处理表单
- humanize : 增加数据的人性化
- localflavor：针对不同国家本地化
- markup : 模板过滤器，用于实现一些常用标记语言
- redirects : 管理重定向
- sessions : 会话
- sitemaps : 网站地图
- sites : 多站点

### `vendor` 目录

应用程序依赖项，`go mod vendor` 命令将创建 `/vendor` 目录

## 服务应用程序目录

### `api` 目录

OpenAPI/Swagger 规范，JSON 模式文件，协议定义文件

参考：<https://github.com/golang-standards/project-layout/blob/master/api/README.md>

例子：<https://github.com/kubernetes/kubernetes/tree/master/api>

```bash
> tree api                         
api
├── api-rules
│   ├── aggregator_violation_exceptions.list
│   ├── apiextensions_violation_exceptions.list
│   ├── codegen_violation_exceptions.list
│   ├── README.md
│   ├── sample_apiserver_violation_exceptions.list
│   └── violation_exceptions.list
├── openapi-spec
│   ├── README.md
│   ├── swagger.json
│   └── v3
│       ├── api_openapi.json
│       ├── apis__admissionregistration.k8s.io_openapi.json
│       ├── apis__admissionregistration.k8s.io__v1alpha1_openapi.json
....
│       ├── api__v1_openapi.json
│       ├── logs_openapi.json
│       ├── openid__v1__jwks_openapi.json
│       └── version_openapi.json
└── OWNERS
```

## Web 应用程序目录

### `web` 目录

特定于 Web 应用程序的组件：静态 Web 资产、服务器端模板和 SPAs

参考：<https://github.com/golang-standards/project-layout/blob/master/web/README.md>

```
├── web/
│   ├── app/
│   ├── static/
│   └── template/
```

## 通用应用目录

### `configs` 目录

配置文件模板或默认配置

参考：<https://github.com/golang-standards/project-layout/blob/master/configs/README.md>

### `init` 目录

System init（systemd，upstart，sysv）和 process manager/supervisor（runit，supervisor）配置

参考：<https://github.com/golang-standards/project-layout/blob/master/init/README.md>

### `scripts` 目录

执行各种构建、安装、分析等操作的脚本

这些脚本保持了根级别的 Makefile 变得小而简单

参考：<https://github.com/golang-standards/project-layout/blob/master/scripts/README.md>

例子：<https://github.com/helm/helm/tree/main/scripts>

### `build` 目录

打包和持续集成

参考：<https://github.com/golang-standards/project-layout/blob/master/build/README.md>

### `deployments` 目录

IaaS、PaaS、系统和容器编排部署配置和模板（docker-compose、kubernetes/helm、mesos、terraform、bosh）

注意，在一些存储库中（特别是使用 kubernetes 部署的应用程序），这个目录被称为 `/deploy`

参考：<https://github.com/golang-standards/project-layout/blob/master/deployments/README.md>

### `test` 目录

额外的外部测试应用程序和测试数据

建议将测试需要的数据存放在 `/testdata`

参考：<https://github.com/golang-standards/project-layout/blob/master/test/README.md>

例子：<https://github.com/openshift/origin/tree/master/test>

## 其他目录

### `docs` 目录

设计和用户文档（除了 godoc 生成的文档之外）

参考：<https://github.com/golang-standards/project-layout/blob/master/docs/README.md>

常用的文档：

- `CONTRIBUTING.md`：如何给项目提交代码的说明，通常包含如何配置开发环境
- `INSTALL_GUIDE.md`：安装向导

### `tools` 目录

项目的支持工具，这些工具可以从 `/pkg` 和 `/internal` 目录导入代码

参考：<https://github.com/golang-standards/project-layout/blob/master/tools/README.md>

### `examples` 目录

应用程序或者公共库的示例

参考：<https://github.com/golang-standards/project-layout/blob/master/examples/README.md>

### `third_party` 目录

外部辅助工具，分叉代码和其他第三方工具（例如 Swagger UI）

参考：<https://github.com/golang-standards/project-layout/blob/master/third_party/README.md>

### `githooks` 目录

Git Hooks

参考：<https://github.com/golang-standards/project-layout/blob/master/githooks/README.md>

### `assets` 目录

与存储库一起使用的其他资产（图像、徽标等）

参考：<https://github.com/golang-standards/project-layout/blob/master/assets/README.md>