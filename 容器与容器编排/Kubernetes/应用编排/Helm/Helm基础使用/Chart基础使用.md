更多请参考官方文档：<https://helm.sh/docs/topics/charts/>

chart 设计参考：https://www.devspace.sh/component-chart/docs/introduction

## Chart 文件结构

chart 通过创建为特定目录树的文件，将它们打包到版本化的压缩包，然后进行部署

```text
chart                           # Chart 目录
├── charts                      # 这个 charts 依赖的其他 charts，始终被安装
├── crds                        # Custom Resource Definitions, CRD 存放目录
├── Chart.yaml                  # 描述这个 Chart 的相关信息、包括名字、描述信息、版本等
├── dashboards                  # 其他存放文件的目录，可以在 templates 中引用
│   └── dex.json
├── templates                   # 模板目录
│   ├── dex-rbac.yaml           # 模板文件
│   ├── dex-config-secret.yaml
│   ├── dex-dashboard.yaml
│   ├── dex-deployment.yaml
│   ├── dex-ingress.yaml
│   ├── dex-service.yaml
│   ├── NOTES.txt                # Chart 部署到集群后的一些信息，例如：如何使用、列出缺省值
│   ├── _helpers.tpl             # 以 _ 开头的文件不会部署到 k8s 上，可用于定制通用信息
│   └── tests                    # 测试 pod 目录
│       └── test-connection.yaml # 测试 pod 的 deployment 文件
├── requirements.yaml            # 列出 chart 依赖项的 YAML 文件
└── values.yaml                  # 模板的值文件，这些值会在安装时应用到 GO 模板生成部署文件

```

## Chart 模版赋值

该对象提供对传入 chart 的值的访问

其内容来自四个来源：

- chart 中的 values.yaml 文件
- 如果这是一个子 chart，来自父 chart 的 values.yaml 文件
- value 文件通过 helm install 或 helm upgrade 的 - f 标志传入文件（`helm install -f my_values.yaml ./my_chart`）
- 通过 `--set`（例如 `helm install --set foo=bar ./my_chart`）

上面的列表按照特定的顺序排列：values.yaml 在默认情况下，父级 chart 的可以覆盖该默认级别，而该 chart values.yaml 又可以被用户提供的 values 文件覆盖，而该文件又可以被 --set 参数覆盖

### 通过 values.yaml 文件取值

创建 chart

```bash
helm create chart-demo
```

查看渲染前的 service.yaml 模板

```tpl
apiVersion: v1
kind: Service
metadata:
  name: {{ include "chart-demo.fullname" . }}
  labels:
    {{- include "chart-demo.labels" . | nindent 4 }}
spec:
  type: {{ .Values.service.type }}
  ports:
    - port: {{ .Values.service.port }}
      targetPort: http
      protocol: TCP
      name: http
  selector:
    {{- include "chart-demo.selectorLabels" . | nindent 4 }}

```

使用 `--dry-run` 命令只渲染模版，而不安装

```bash
helm install --dry-run demo .
```

渲染的结果为

```yaml
# Source: chart-demo/templates/service.yaml
apiVersion: v1
kind: Service
metadata:
  name: demo-chart-demo
  labels:
    helm.sh/chart: chart-demo-0.1.0
    app.kubernetes.io/name: chart-demo
    app.kubernetes.io/instance: demo
    app.kubernetes.io/version: "1.16.0"
    app.kubernetes.io/managed-by: Helm
spec:
  type: ClusterIP
  ports:
    - port: 80
      targetPort: http
      protocol: TCP
      name: http
  selector:
    app.kubernetes.io/name: chart-demo
    app.kubernetes.io/instance: demo
```

编辑 values.yaml 文件，将 service.port 值改为 8080

```yaml
···
service:
  type: ClusterIP
  port: 8080
···
```

查看渲染后的 service.yaml 文件，可以看到 8080 已经被渲染进模版

```yaml
# Source: chart-demo/templates/service.yaml
apiVersion: v1
kind: Service
metadata:
  name: demo-chart-demo
  labels:
    helm.sh/chart: chart-demo-0.1.0
    app.kubernetes.io/name: chart-demo
    app.kubernetes.io/instance: demo
    app.kubernetes.io/version: "1.16.0"
    app.kubernetes.io/managed-by: Helm
spec:
  type: ClusterIP
  ports:
    - port: 8080
      targetPort: http
      protocol: TCP
      name: http
  selector:
    app.kubernetes.io/name: chart-demo
    app.kubernetes.io/instance: demo
```

### 手动使用 --set 指定

注意： --set 的值会覆盖 values.yaml 中预设的值

使用 --set 命令，将 service.port 值更改为 9090

```bash
helm install --set service.port=9090 --dry-run demo .
```

查看渲染后的 service.yaml 文件，可以看到 9090 已经被渲染进模版

```yaml
# Source: chart-demo/templates/service.yaml
apiVersion: v1
kind: Service
metadata:
  name: demo-chart-demo
  labels:
    helm.sh/chart: chart-demo-0.1.0
    app.kubernetes.io/name: chart-demo
    app.kubernetes.io/instance: demo
    app.kubernetes.io/version: "1.16.0"
    app.kubernetes.io/managed-by: Helm
spec:
  type: ClusterIP
  ports:
    - port: 9090
      targetPort: http
      protocol: TCP
      name: http
  selector:
    app.kubernetes.io/name: chart-demo
    app.kubernetes.io/instance: demo
```

### 通过 -f 指定文件

创建 demo.yaml 文件，内容如下

```yaml
service:
  type: ClusterIP
  port: 7070
```

通过 demo.yaml 文件渲染

```bash
helm install -f ./demo.yaml --dry-run demo .
```

查看渲染后的 service.yaml 文件，可以看到 7070 已经被渲染进模版，说明指定的文件会覆盖 values.yaml 中相同的参数

```yaml
# Source: chart-demo/templates/service.yaml
apiVersion: v1
kind: Service
metadata:
  name: demo-chart-demo
  labels:
    helm.sh/chart: chart-demo-0.1.0
    app.kubernetes.io/name: chart-demo
    app.kubernetes.io/instance: demo
    app.kubernetes.io/version: "1.16.0"
    app.kubernetes.io/managed-by: Helm
spec:
  type: ClusterIP
  ports:
    - port: 7070
      targetPort: http
      protocol: TCP
      name: http
  selector:
    app.kubernetes.io/name: chart-demo
    app.kubernetes.io/instance: demo
```

## 预定义值

通过 values.yaml 文件（或通过 --set 标志）提供的值可以从 .Values 模板中的对象访问。可以在模板中访问其他预定义的数据片段。

以下值是预定义的，可用于每个模板，并且不能被覆盖。与所有值一样，名称区分大小写。

- `Release.Name`：release 的名称（不是 chart 的）
- `Release.Time`：chart 版本上次更新的时间。这将匹配 Last Released 发布对象上的时间。
- `Release.Namespace`：chart release 发布的 namespace。
- `Release.Service`：处理 release 的服务。通常是 Tiller。
- `Release.IsUpgrade`：如果当前操作是升级或回滚，则设置为 true。
- `Release.IsInstall`：如果当前操作是安装，则设置为 true。
- `Release.Revision`：版本号。它从 1 开始，并随着每个 helm upgrade 增加。
- `Chart`：Chart.yaml 的内容。chart 版本可以从 Chart.Version 和维护人员 Chart.Maintainers 一起获得。
- `Files`：包含 chart 中所有非特殊文件的 map-like 对象。不会允许你访问模板，但会让你访问存在的其他文件（除非它们被排除使用 `.helmignore` ）。可以使用 `index .Files "file.name"` 或使用 `.Files.Get name` 或 `.Files.GetString name` 功能来访问- `文件。也可以使用 .`Files.GetBytes` 访问该文件的内容 `[byte]`
- `Capabilities`：包含有关 Kubernetes 版本信息的 map-like 对象（`.Capabilities.KubeVersion`)，Tiller（`.Capabilities.TillerVersion`)和支持的 Kubernetes API 版本（`.Capabilities.APIVersions.Has "batch/v1"`）

## Chart 模版语法

模板函数文档：<https://helm.sh/zh/docs/chart_template_guide/function_list>

### quote 函数

当从 `.Values` 对象注入字符串到模板中时，引用这些字符串可以通过调用 quote 模板指令中的函数来实现

```yaml
type: {{ quote .Values.service.type }}
```

### 管道

模板语言的强大功能之一是其管道概念。利用 UNIX 的一个概念，管道是一个链接在一起的一系列模板命令的工具，以紧凑地表达一系列转换。

换句话说，管道是按顺序完成几件事情的有效方式。

```yaml
type: {{ .Values.service.type | upper | quote }}
```

### default 函数

经常使用的一个函数是

```yaml
default：default DEFAULT_VALUE GIVEN_VALUE
```

该功能允许在模板内部指定默认值，以防该值被省略

```yaml
port: {{ .Values.service.port | default 9999 }}
```

### nindent 函数

nindent 模板函数，从左开始留出指定空格，并在最前方添加一个换行

```bash
resources:
  {{- toYaml .Values.resources | nindent 4 }}
```

等效于换行

```bash
resources: {{ toYaml .Values.resources | nindent 12 }}
```

### with

with 可以允许将当前范围 `.` 设置为特定的对象。例如，`.Values.service`，使用 with 可以将 `.Values.service` 改为 `.`

现在可以引用 `.port` 和 .`type` 无需对其进行限定。这是因为该 with 声明设置 `.` 为指向 `.Values.service`。在 `{{ end }}` 后 `.` 复位其先前的范围。

```yaml
piVersion: v1
kind: Service
metadata:
  name: {{ include "chart-demo.fullname" . }}
  labels:
    {{- include "chart-demo.labels" . | nindent 4 }}
spec:
  {{- with .Values.service }}
  type: {{ .type }}
  ports:
    - port: {{ .port }}
      targetPort: http
      protocol: TCP
      name: http
  {{- end }}
  selector:
    {{- include "chart-demo.selectorLabels" . | nindent 4 }}

```

### 变量

在 Helm 模板中，变量是对另一个对象的命名引用。它遵循这个形式 `$name`。变量被赋予一个特殊的赋值操作符：`:=`。

```yaml
env:
  {{- range $key, $value := .Values.env }}
  - name: {{ $key }}
    value: {{ $value | quote }}
  {{- end }}

```

### if-else

遵循如下语法：

```yaml
{{if PIPELINE}}
  # Do something
{{else if OTHER PIPELINE}}
  # Do something else
{{else}}
  # Default case
{{end}}
```

如果值为如下情况，则管道评估为 false。

- 一个布尔型的假
- 一个数字零
- 一个空的字符串
- 一个 nil（空或 null）
- 一个空的集合（map，slice，tuple，dict，array）

```yaml
{{- if eq .Values.favorite.drink "coffee" }}
mug: true
{{- end}}
```

### 其他模板函数

- trim：移除字符串两边的空格

```bash
trim "   hello    "
```

- trimAll：从字符串中移除给定的字符

```bash
trimAll "$" "$5.00"
```

- trimPrefix：从字符串中移除前缀

```bash
trimPrefix "-" "-hello"
```

- trimSuffix：从字符串中移除后缀

```bash
trimSuffix "-" "hello-"
```

- lower：将整个字符串转换成小写
- upper：将整个字符串转换成大写

```bash
lower "HELLO"
upper "hello"
```

- title：首字母转换成大写
- untitle：移除首字母大写

```bash
title "hello world"
untitle "Hello World"
```

- indent：以指定长度缩进给定字符串所在行

## 命名模板

一般在 template 文件夹下的 `_helpers.tpl` 中定义命名模板；通过 define 函数定义命名模板，template 使用命名模板

在 `_helpers.tpl` 文件内添加一个模版

```tpl
···
{{/*
Demo template
*/}}
{{- define "my_labels" }}
  labels:
    generator: helm
    date: {{ now | htmlDate }}
    chart: {{ .Chart.Name }}
    version: {{ .Chart.Version }}
{{- end }}

```

在 configmap 中使用该模版

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: {{ .Release.Name }}-configmap
  {{- template "my_labels" . }}

```

查看渲染后的 configmap.yaml

```yaml
# Source: chart-demo/templates/configmap.yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: demo-configmap
  labels:
    generator: helm
    date: 2022-09-03
    chart: chart-demo
    version: 0.1.0
```
