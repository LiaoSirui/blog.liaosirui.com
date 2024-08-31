
更多请参考官方文档：<https://helm.sh/docs/topics/library_charts/#helm>

## 简介

库 Chart 是一种 Helm Chart ，它定义了 Chart 原语或定义，可以由 Helm 模板在其他 Chart 中共享。这允许用户共享可以跨 Chart 重复使用的代码片段，避免重复并保持 Chart DRY（Don't repeat yourself）。

通过将其作为图表类型包含在内，它提供：

- 一种明确区分公共 Chart 和应用 Chart 的方法
- 防止安装公共 Chart 的逻辑
- 公共 Chart 中不提供用于发布的模板

## 创建一个简单的公共库

它也是 Chart 的一种，所以仍然可以用 Chart 的创建方式

```bash
helm create chart-common
```

首先删除 templates 目录中的所有文件，因为将在示例中创建自己的模板定义

```bash
rm -rf chart-common/templates/*
```

也不需要值文件

```bash
rm -f chart-common/values.yaml
```

在templates/目录中， 所有以下划线开始的文件 (`_`) 不会输出到 Kubernetes 清单文件中。因此依照惯例，辅助模板和局部模板被放置在 `_*.tpl` 或 `_*.yaml`文件中。

## 编写公共库

这个示例中，我们要写一个通用的配置映射来创建一个空的配置映射源。在 `chart-common/templates/_configmap.yaml` 文件中定义如下：

```yaml
{{- define "chart-common.configmap.tpl" -}}
apiVersion: v1
kind: ConfigMap
metadata:
  name: {{ .Release.Name | printf "%s-%s" .Chart.Name }}
data: {}
{{- end -}}

{{- define "chart-common.configmap" -}}
{{- include "chart-common.util.merge" (append . "chart-common.configmap.tpl") -}}
{{- end -}}
```

这个配置映射结构被定义在名为 `chart-common.configmap.tpl` 的模板文件中

data 是一个空源的配置映射， 这个文件中另一个命名的模板是 `chart-common.configmap`。这个模板包含了另一个模板 `chart-common.util.merge`，会使用两个命名的模板作为参数，称为 `chart-common.configmap` 和 `chart-common.configmap.tpl`。

复制方法 `chart-common.util.merge` 是 `chart-common/templates/_util.yaml` 文件中的一个命名模板。 是通用 Helm 辅助 Chart 的实用工具。因为它合并了两个模板并覆盖了两个模板的公共部分。

```yaml
{{- /*
chart-common.util.merge will merge two YAML templates and output the result.
This takes an array of three values:
- the top context
- the template name of the overrides (destination)
- the template name of the base (source)
*/}}
{{- define "chart-common.util.merge" -}}
{{- $top := first . -}}
{{- $overrides := fromYaml (include (index . 1) $top) | default (dict ) -}}
{{- $tpl := fromYaml (include (index . 2) $top) | default (dict ) -}}
{{- toYaml (merge $overrides $tpl) -}}
{{- end -}}
```

最后，将 chart 类型修改为 library

```yaml
apiVersion: v2
name: chart-common
description: A Helm chart for Kubernetes

# A chart can be either an 'application' or a 'library' chart.
#
# Application charts are a collection of templates that can be packaged into versioned archives
# to be deployed.
#
# Library charts provide useful utilities or functions for the chart developer. They're included as
# a dependency of application charts to inject those utilities and functions into the rendering
# pipeline. Library charts do not define any templates and therefore cannot be deployed.
# type: application
type: library

# This is the chart version. This version number should be incremented each time you make changes
# to the chart and its templates, including the app version.
version: 0.1.0

# This is the version number of the application being deployed. This version number should be
# incremented each time you make changes to the application and it is recommended to use it with quotes.
appVersion: "1.16.0"
```

此时，有必要去检测一下 chart 是否变成了库 chart：

```bash
> helm install chart-common chart-common/

Error: library charts are not installable
```
