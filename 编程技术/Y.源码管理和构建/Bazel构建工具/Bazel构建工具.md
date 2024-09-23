## Bazel 简介

`Bazel`是一个支持多语言、跨平台的构建工具。`Bazel`支持任意大小的构建目标，并支持跨多个仓库的构建，是 Google 主推的一种构建工具

`bazel`优点很多，主要有

- 构建快。支持增量编译。对依赖关系进行了优化，从而支持并发执行
- 可构建多种语言。bazel可用来构建Java C++ Android ios等很多语言和框架，并支持mac windows linux等不同平台
- 可伸缩。可处理任意大小的代码库，可处理多个库，也可以处理单个库
- 可扩展。使用bazel扩展语言可支持新语言和新平台

如果一个项目不同模块使用不同的语言，利用`Bazel`可以使用一致的风格来管理项目外部依赖和内部依赖。典型的项目如 Ray。该项目使用`C++`构建`Ray`的核心调度组件、通过`Python/Java`来提供多语言的`API`，并将上述所有模块用单个`repo`进行管理。如此组织使其项目整合相当困难，但`Bazel`在此处理的游刃有余

`Bazel`使用的语法是基于`Python`裁剪而成的一门语言：`Startlark`。其表达能力强大，往小了说，可以使用户自定义一些`rules`（类似一般语言中的函数）对构建逻辑进行复用；往大了说，可以支持第三方编写适配新的语言或平台的`rules`集，比如`rules go`。 `Bazel`并不原生支持构建`golang`工程，但通过引入`rules go` ，就能以比较一致的风格来管理`golang`工程

### 主要的文件

使用`Bazel`管理的项目一般包含以下几种`Bazel`相关的文件：`WORKSPACE，BUILD(.bazel)，.bzl` 和 `.bazelrc` 等。其中 `WORKSPACE` 和 `.bazelrc` 放置于项目的根目录下，`BUILD.bazel` 放项目中的每个文件夹中（包括根目录），`.bzl`文件可以根据用户喜好自由放置，一般可放在项目根目录下的某个专用文件夹（比如 build）中

- WORKSPACE

定义项目根目录和项目名。加载 Bazel 工具和 rules 集。管理项目外部依赖库

- BUILD.bazel

存在于根目录以及源文件所在目录，用来标记源文件编译以及依赖情况，一般是自动生成。拿 go 来说，构建目标可以是 `go_binary、go_test、go_library `等

- 自定义 rule (`*.bzl`)

如果你的项目有一些复杂构造逻辑、或者一些需要复用的构造逻辑，那么可以将这些逻辑以函数形式保存在 `.bzl` 文件，供`WORKSPACE`或者`BUILD`文件调用。其语法跟`Python`类似：

```bazel
def third_party_http_deps():
    http_archive(
        name = "xxxx",
        ...
    )

    http_archive(
        name = "yyyy",
        ...
    )
```

- 配置项 `.bazelrc`

对于`Bazel`来说，如果某些构建动作都需要某个参数，就可以将其写在此配置中，从而省去每次敲命令都重复输入该参数。举个 Go 的例子：构建、测试和运行时可能都需要`GOPROXY`，则可以配置如下：

```bash
# set GOPROXY
test --action_env=GOPROXY=https://goproxy.io
build --action_env=GOPROXY=https://goproxy.io
run --action_env=GOPROXY=https://goproxy.io
```

### 安装

安装 `Bazel`

```bash
INST_BAZEL_VERSION=v7.3.1

wget "https://github.com/bazelbuild/bazel/releases/download/${INST_BAZEL_VERSION/v/}/bazel-${INST_BAZEL_VERSION/v/}-linux-x86_64" \
    -O /usr/local/bazel-${INST_BAZEL_VERSION/v/}-linux-x86_64
chmod +x /usr/local/bazel-${INST_BAZEL_VERSION/v/}-linux-x86_64

update-alternatives --install /usr/bin/bazel bazel /usr/local/bazel-${INST_BAZEL_VERSION/v/}-linux-x86_64 1
update-alternatives --set bazel /usr/local/bazel-${INST_BAZEL_VERSION/v/}-linux-x86_64
```

安装 `gazelle`

```bash
go install github.com/bazelbuild/bazel-gazelle/cmd/gazelle@latest
```

## rule

rule（规则）内置规则（以 c 为例子）规则说明 cc_library 用于构建 C 或 C++ 库的规则。它接受源代码文件、头文件、编译选项等作为输入，并生成静态库或动态库文件作为输出。cc_binary 用于构建 C 或 C++ 可执行文件的规则。它接受源代码文件、头文件、依赖库等作为输入，并生成可执行文件作为输出。cc_test 用于构建 C 或 C++ 测试的规则。它接受测试源代码文件、头文件、依赖

### 内置规则

以 C 为例：

| 规则            | 说明                                                         |
| :-------------- | :----------------------------------------------------------- |
| cc_library      | 用于构建 C 或 C++ 库的规则。它接受源代码文件、头文件、编译选项等作为输入，并生成静态库或动态库文件作为输出。 |
| cc_binary       | 用于构建 C 或 C++ 可执行文件的规则。它接受源代码文件、头文件、依赖库等作为输入，并生成可执行文件作为输出。 |
| cc_test         | 用于构建 C 或 C++ 测试的规则。它接受测试源代码文件、头文件、依赖库等作为输入，并生成可执行的测试程序。 |
| cc_import       | 用于导入外部的 C 或 C++ 库的规则。它用于引入已经存在的库文件或第三方库，以便在项目中使用。 |
| filegroup       | 用于将一组文件打包为单个逻辑组，并在构建过程中一起处理。     |
| exports_files   | 用于将指定的文件或目录导出到目标的运行时环境中。             |
| genrule         | 用于执行任意命令并生成文件作为输出的规则。                   |
| data            | 用于将文件或目录复制到目标的输出目录中，以供其他目标使用。   |
| sh_binary       | 用于构建和运行Shell脚本的规则。                              |
| container_image | 用于构建和管理容器镜像的规则。                               |
| setting_group   | 用于将一组构建设置（如编译选项、宏定义、环境变量等）组织在一起，并在构建文件中使用。 |
| string_flag     | 用于接受命令行标志的字符串值作为输入。然后在构建文件中使用这个标志的值来配置不同的规则、目标或构建操作。 |

### 自定义规则

使用 Starlark 语言自定义规则函数，自定义规则一般放入 `.bzl` 文件中。

自定义规则分为三步：定义规则函数、注册规则、使用规则

#### 定义规则函数

使用 Starlark 语言定义规则函数

`custom_rules.bzl` 中

```bazel
# ctx 为上下文对象，可以调用上下文中的参数
def rule_impl(ctx):
	# 规则函数实现
	input_file = ctx.attr.input_file

```

#### 注册规则

`custom_rules.bzl` 中

```bazel
my_rule = rule(
	implementation = rule_impl,
    attrs = {
        "input_file": attr.string(),
        "output_file": attr.string(),
    },	
)

```

#### 使用规则

在 BUILD 文件中，通过 `load()` 函数，加载自定义规则。然后可以直接使用函数调用的方式使用规则

```bazel
# ":custom_rules.bzl"为规则文件的标签， my_rule 是需要加载的自定义规则
load(":custom_rules.bzl", "my_rule")
# 调用规则
my_rule(
    # 指定调用规则后生成的目标名
    name = "my_rule_target",
    # 自定义参数传递，将值 “input.txt” 传递给参数 input_file
    input_file= "input.txt",
    output_file= "output.txt",
)

```

外部依赖：<https://paulyangtools.blogspot.com/2018/04/bazel-workspace.html>

## 参考资料

- <https://blog.v5u.win/posts/go/go-bazel%E6%9E%84%E5%BB%BA%E5%B7%A5%E5%85%B7/>
- <https://juejin.cn/post/7193268970881810489>
- <https://juejin.cn/post/7195554661318246455>
- <https://bazel.build/install/docker-container?hl=zh-cn>
- <https://blog.51cto.com/u_16213302/12012155>

- <https://www.cnblogs.com/ssgeek/p/15600966.html>

- <https://htl2018.github.io/2020/04/05/bazel%E5%85%A5%E9%97%A8/>