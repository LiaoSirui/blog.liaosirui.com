## 简介

`PDM` 全名 `Python Development Master`

官方：

- GitHub 仓库：<https://github.com/pdm-project/pdm>
- 官网：<https://pdm.fming.dev/latest/>

## 安装方式

PDM 需要安装 Python 3.8+

```bash
pipx install pdm[all]

# 设置补全
pdm completion bash > /etc/bash_completion.d/pdm.bash-completion
pdm completion zsh > ~/.zfunc/_pdm
```

生态系统：<https://github.com/pdm-project/awesome-pdm>

## 使用

### 初始化项目

使用 `PDM` 初始化项目很简单，只需要创建一个文件夹，然后进入文件夹中执行 `pdm init` 命令即可完成初始化

```bash
pdm init
```

初始化完成后项目中会生成如下文件：

- 解释器路径将被存储在 `.pdm-python` 文件中，可以使用 [`pdm use`](https://pdm-project.org/zh-cn/latest/reference/cli/#use)命令更改它，通过 `PDM_PYTHON`环境变量指定 Python 解释器路径。设置后，保存的 `.pdm-python` 路径将被忽略

- PDM 会向 `pyproject.toml` 文件添加 `name`、`version` 字段，以及一个 [build backend](https://pdm-project.org/zh-cn/latest/reference/build/) 表格用于构建后端

  - 在 `pyproject.toml` 中，在 `[tool.pdm]` 表下有一个字段 `distribution`。如果将其设置为 `true` ，PDM 将把该项目视为一个库。当运行 `pdm install` 或 `pdm sync` 时，库项目将被安装到环境中，除非指定了`--no-self`

  - `requires-python` 的值是根据 [PEP 440](https://peps.python.org/pep-0440/#version-specifiers)定义的版本指定符

- `pdm.lock` 和 `pdm.toml` 文件

### 给项目添加依赖包

和大多数的包管理工具一样，`PDM` 也是用 `add` 指令。

[`pdm add`](https://pdm-project.org/zh-cn/latest/reference/cli/#add) 后面可以跟着一个或多个依赖项，依赖项的规范在 [PEP 508](https://www.python.org/dev/peps/pep-0508/) 中描述

添加 `requests` 的过程：

```bash
pdm add request
```

和 Poetry 一样，安装使用的是 add 命令，但 pdm 的 add 比 poetry 好用，主要体现在分组：

- PDM 还允许通过提供 `-G/--group <name>` 选项来添加额外的依赖项组， 这些依赖项将分别进入项目文件中的 `[project.optional-dependencies.<name>]` 表。
- PDM 也支持定义对开发有用的依赖组。 例如，一些用于测试，另一些用于代码检查。我们通常不希望这些依赖项出现在发行版的元数据中

额外的依赖项组 vs 开发依赖

```bash
[project]  # 这是生产依赖项
dependencies = ["requests"]

[project.optional-dependencies]  # 这是可选依赖项
extra1 = ["flask"]
extra2 = ["django"]

[tool.pdm.dev-dependencies]  # 这是开发依赖项
dev1 = ["pytest"]
dev2 = ["mkdocs"]
```

可以使用其路径添加本地包。路径可以是文件或目录：

```bash
pdm add ./sub-package
pdm add ./first-1.0.0-py2.py3-none-any.whl
```

还可以从 git 存储库 URL 或其他版本控制系统安装。要对 git 使用 ssh 方案，只需将 "https://" 替换为 "ssh://git@"

```bash
# 在标签 `22.0` 上安装 pip 存储库
pdm add "git+https://github.com/pypa/pip.git@22.0"
# 在 URL 中提供凭据
pdm add "git+https://username:password@github.com/username/private-repo.git@master"
# 为依赖项命名
pdm add "pip @ git+https://github.com/pypa/pip.git@22.0"
# 或使用 #egg 片段
pdm add "git+https://github.com/pypa/pip.git@22.0#egg=pip"
# 从子目录安装
pdm add "git+https://github.com/owner/repo.git@master#egg=pkg&subdirectory=subpackage"

pdm add "wheel @ git+ssh://git@github.com/pypa/wheel.git@main"
```

可以使用 `${ENV_VAR}` 变量语法在 URL 中隐藏凭据，这些变量将从环境变量中读取。

```toml
[project]
dependencies = [
  "mypackage @ git+http://${VCS_USER}:${VCS_PASSWD}@test.git.com/test/mypackage.git@master"
]
```

本地目录 和 VCS 依赖项 可以以 可编辑模式 安装

```bash
# 相对路径到目录
pdm add -e ./sub-package --dev
# 到本地目录的文件 URL
pdm add -e file:///path/to/sub-package --dev
# VCS URL
pdm add -e git+https://github.com/pallets/click.git@main#egg=click --dev
```

### 查看项目依赖包

使用 `pdm list` 可以以列表形式列出当前环境已安装的包：

```bash
pdm list --tree

# 显示为什么需要特定的包
pdm list --tree --reverse certifi
```

能以树状形式查看，直接依赖包和间接依赖包关系的层级一目了然

### 对于已有的项目进行初始化

执行命令

```bash
pdm install
```

## 配置多个源

官方文档地址：<https://pdm.fming.dev/1.15/pyproject/tool-pdm/#specify-other-sources-for-finding-packages>

多个源的配置示例：

```toml
[tool.pdm]
    [[tool.pdm.source]]
        name       = "pypi"
        url        = "http://devpi.local.liaosirui.com:3141/root/douban/+simple/"
        verify_ssl = true
    [[tool.pdm.source]]
        name       = "torch-cu116"
        url        = "http://devpi.local.liaosirui.com:3141/root/torch-cu116/+simple/"
        verify_ssl = false

```

## 方案兼容

### 其他方案迁移到 pdm

如果当前使用的是其他的包管理器，比如 pipenv ，poetry，或者还在用最原始的 requirements.txt ，也可以很方便的迁移到 pdm 中来：

- 使用 `pdm import -f {file}` 无需初始化，直接转换

- 执行 `pdm init` 或者 `pdm install `的时候，会自动识别当前的依赖情况并转换

### pdm 迁移到其他方案

可以将 pdm 管理的项目，导出为其他方案

- 将 pyproject.toml 转成 setup.py（暂未支持，<https://pdm.fming.dev/latest/usage/project/#export-locked-packages-to-alternative-formats>）

```bash
pdm export -f setuppy -o setup.py
# pdm export -f setuppy -o setup.py --without-hashes --pyproject --prod
```

- 将 pdm.lock 转成 requirements.txt

```bash
pdm export -o requirements.txt
```

## 创建 3.6 环境

py36 无法使用 pdm，因此手动创建 venv

```bash
cd py36
$(pyenv root)/shims/python3.6 -m venv --copies .venv
```

首次初始化

```bash
pdm init --python .venv/bin/python3
```

安装

```bash
pdm install --venv .venv
```

## 参考资料

- <http://fancyerii.github.io/2024/03/11/pdm-tutorial/>

