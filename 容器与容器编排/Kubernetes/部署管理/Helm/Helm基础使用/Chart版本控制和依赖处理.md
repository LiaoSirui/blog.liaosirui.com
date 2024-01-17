
更多请参考官方文档：<https://helm.sh/docs/topics/charts/>

## charts 版本控制

- 遵循 SemVer2 标准

每个 chart 都必须有一个版本号。版本必须遵循 SemVer 2 标准。与 Helm Class 格式不同，Kubernetes Helm 使用版本号作为发布标记。存储库中的软件包由名称加版本识别。

Semantic Versioning 2.0.0 文档：<https://semver.org/>

更复杂的 SemVer 2 命名也是支持的，例如 `version: 1.2.3-alpha.1+ef365`。但非 SemVer 命名是明确禁止的。

- appVersion字段

请注意，appVersion 字段与 version 字段无关。这是一种指定应用程序版本的方法

- 弃用 charts

在管理 chart repo 库中的 chart 时，有时需要弃用 chart。Chart.yaml 的 deprecated 字段可用于将 chart 标记为已弃用。

如果存储库中最新版本的 chart 标记为已弃用，则整个 chart 被视为已弃用。chart 名称稍后可以通过发布未标记为已弃用的较新版本来重新使用。

废弃 chart 的工作流程根据 kubernetes/charts 项目的工作流程如下：（1）更新 chart的Chart.yaml 以将 chart 标记为启用，并且更新版本（2）在chart Repository中发布新的chart版本

## Chart 依赖关系

在 Helm 中，一个 chart 可能依赖于任何数量的其他 chart。这些依赖关系可以通过 requirements.yaml 文件动态链接或引入 `charts/` 目录并手动管理

虽然有一些团队需要手动管理依赖关系的优势，但声明依赖关系的首选方法是使用 chart 内部的 requirements.yaml 文件

注意：传统 Helm 的 Chart.yaml `dependencies:`部分字段已被完全删除弃用

### 用 requirements.yaml 来管理依赖关系

#### 处理依赖

requirements.yaml 文件是列出 chart 的依赖关系的简单文件

```yaml
dependencies:
- name: chart-demo
  version: 0.1.0
  repository: oci://localhost:5000/helm-charts
# - name: apache
#   version: 1.2.3
#   repository: http://example.com/charts
# - name: mysql
#   version: 3.2.1
#   repository: http://another.example.com/charts

```

- 该 name 字段是 chart 的名称
- version 字段是 chart 的版本
- repository 字段是 chart repo 的完整 URL；请注意，还必须使用 helm repo add 添加该 repo 到本地才能使用

有了依赖关系文件，可以通过运行 `helm dependency update` ，它会使用你的依赖关系文件将所有指定的 chart 下载到你的 `charts/` 目录中

当 `helm dependency update` 检索 chart 时，它会将它们作为 chart 存档存储在 `charts/` 目录中。因此，对于上面的示例，可以在 chart 目录中看到以下文件：

```bash
charts/
└── chart-demo-0.1.0.tgz

```

#### 多次引入同一依赖

通过 requirements.yaml 管理 chart 是一种轻松更新 chart 的好方法，还可以在整个团队中共享 requirements 信息

如果需要使用其他名称访问 chart，可以使用 alias

```yaml
# parent-chart/requirements.yaml
dependencies:
- name: subchart
  repository: http://localhost:10191
  version: 0.1.0
  alias: new-subchart-1
- name: subchart
  repository: http://localhost:10191
  version: 0.1.0
  alias: new-subchart-2
- name: subchart
  repository: http://localhost:10191
  version: 0.1.0

```

在上面的例子中，我们将得到 parent-chart 的 3 个依赖关系

实现这一目的的手动方法是 `charts/` 中用不同名称多次复制 / 粘贴目录中的同一 chart

#### tags 和 conditions

除上述其他字段外，每个需求条目可能包含可选字段 tags 和 condition；所有 charts 都会默认加载，如果存在 tags 或 condition 字段，将对它们进行评估并用于控制应用的 chart 的加载

- Condition – condition 字段包含一个或多个 YAML 路径（用逗号分隔）。如果此路径存在于顶级父级的值中并且解析为布尔值，则将根据该布尔值启用或禁用 chart。只有在列表中找到的第一个有效路径才被评估，如果没有路径存在，那么该条件不起作用。
- Tags – 标签字段是与此 chart 关联的 YAML 标签列表。在顶级父级的值中，可以通过指定标签和布尔值来启用或禁用所有带有标签的 chart。

```yaml
# parent-chart/requirements.yaml
dependencies:
- name: subchart1
  repository: http://localhost:10191
  version: 0.1.0
  condition: subchart1.enabled, global.subchart1.enabled
  tags:
  - front-end
  - subchart1

- name: subchart2
  repository: http://localhost:10191
  version: 0.1.0
  condition: subchart2.enabled,global.subchart2.enabled
  tags:
  - back-end
  - subchart2
```

对应的 values.yaml 文件

```yaml
# parent-chart/values.yaml

subchart1:
  enabled: true

tags:
  front-end: false
  back-end: true

```

在上面的示例中，所有带有标签的 front-end 的 charts 都将被禁用，但由于 subchart1.enabled 的值在父项值中为“真”，因此条件将覆盖该 front-end 标签，subchart1 会启用。

由于 subchart2 被标记 back-end 和标签的计算结果为 true，subchart2 将被启用。还要注意的是，虽然 subchart2 有一个在 requirements.yaml 中指定的条件，但父项的值中没有对应的路径和值，因此条件无效。

tags 和 conditions 解析：

- Conditions (设置 values) 会覆盖 tags 配置.。第一个存在的 condition 路径生效，后续该 chart 的 condition 路径将被忽略
- 如果 chart 的某 tag 的任一 tag 的值为 true，那么该 tag 的值为 true，并启用这个 chart
- Tags 和 conditions 值必须在顶级父级的值中进行设置
- `tags:` 值中的关键字必须是顶级关键字。目前不支持全局和嵌套 `tags:`

### 通过 `charts/` 目录手动管理依赖性

如果需要更多的控制依赖关系，可以通过将依赖的 charts 复制到 `charts/` 目录中来明确表达这些依赖关系。
