
## Chart 名称

- chart 名称必须是小写字母和数字
- 单词之间可以使用破折号 `-` 分隔
- chart 名称中不能用大写字母也不能用下划线、点 `.` 也不行

## YAML 格式

YAML 文件应该按照双空格缩进，不能使用 tab

## values

命名规范：

- 变量名称采用驼峰命名
- 以小写字母开头

注意所有的 Helm 内置变量以大写字母开头，以便与用户定义的 value 进行区分：`.Release.Name`

## 模版

### 文件名

模板文件名称应该使用 `-` 符号，例如 `my-example-configmap.yaml`，不用驼峰法

模板文件的名称应该反映名称中的资源类型。比如：`foo-pod.yaml`，`bar-svc.yaml`

### 模版内容

模板应该使用两个空格缩进（永远不要用 tab）

模板命令的大括号前后应该使用空格

### 注释

模板注释

```helm
{{/*
my_chart.shortname provides a 6 char truncated version of the release name.
*/}}
```

yaml 注释

```yaml
# This is a comment
type: sprocket
```

## 模板函数和流水线

模板函数遵循的语法是

```helm
functionName arg1 arg2...
```

### 管道符

使用管道符 `|` 将参数发送给函数：

```helm
.Values.favorite.drink | quote
```

这里倒置了命令
