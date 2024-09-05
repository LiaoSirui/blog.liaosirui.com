
## helm lint

helm lint 是验证 chart 是否遵循最佳实践的首选工具

当你想测试模板渲染但又不想安装任何内容时，可以使用

```bash
helm install --debug --dry-run goodly-guppy ./chart
```

## 为什么要 Helm 单元测试

Helm 使用的模板语言是 Go Template，而这种模板语言非常难维护，所以，Helm 的 Chart 包也就变得难维护

当写好 Chart 中的 YAML 文件后，只能通过手工执行 Helm template 命令去验证它的语法正确性

这样做的弊端有：

1. 无法自动化验证
2. 无法重复验证

## 如何进行 Helm 单元测试

Helm3 的单元测试需要以下几步：

1. 安装 helm3-unittest 插件 ；
2. 将 `$YOUR_CHART/tests` 加入到 `.helmignore`，因为不需要将 tests 目录打包进最终的 chart 包中；
3. 编写单元测试代码；
4. 集成到持续集成流水线

## 单元测试详细步骤

### 安装 helm3-unittest 插件

```bash
helm plugin install https://github.com/vbehar/helm3-unittest
```

也可以加 --version 参数指定版本

```bash
helm plugin install --version 1.0.16 https://github.com/vbehar/helm3-unittest
```

### 编写单元测试

创建一个单元测试案例 `$YOUR_CHART/tests/deployment_test.yaml`

```yaml
suite: test deployment
templates:
  - deployment.yaml
tests:
  - it: should pass all kinds of assertion
    values:
     # 指定一个values文件 相对于 $YOUR_CHART/tests路径。
      - ./values/image.yaml
    set:
      # 覆盖以上values的一项配置
      service.internalPort: 8080
    asserts:
      - equal:
          path: spec.template.spec.containers[0].image
          value: apache:latest
      - notEqual:
          path: spec.template.spec.containers[0].image
          value: nginx:stable
      - matchRegex:
          path: metadata.name
          pattern: ^.*-basic$
      - notMatchRegex:
          path: metadata.name
          pattern: ^.*-foobar$
      - contains:
          path: spec.template.spec.containers[0].ports
          content:
            containerPort: 8080
      - notContains:
          path: spec.template.spec.containers[0].ports
          content:
            containerPort: 80
      - isNull:
          path: spec.template.nodeSelector
      - isNotNull:
          path: spec.template
      - isEmpty:
          path: spec.template.spec.containers[0].resources
      - isNotEmpty:
          path: spec.template.spec.containers[0]
      - isKind:
          of: Deployment
      - isAPIVersion:
          of: extensions/v1beta1
      - hasDocuments:
          count: 2
      - matchSnapshot:
          path: spec
```

### 进行单元测试

1. 创建 `$YOUR_CHART/tests` 目录。注意，不是 `$YOUR_CHART/templates/tests` 目录。
2. 在 `$YOUR_CHART/tests` 目录写单元测试。
3. 在 repo 的根目录执行命令：`helm unittest`

## 其他

Helm 单元测试只是测试 Helm 语法级别的错误，并不能测试到它真正运行在 K8s 的效果

如果要测试它真正运行在 K8s 上的效果，需要集成测试
