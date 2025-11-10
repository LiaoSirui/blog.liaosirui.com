## pre-commit 简介

在版本控制系统中，hook 是一种脚本，用于在某些事件发生时触发。例如，在 Git 中，可以设置一个 hook 在提交前运行

`pre-commit` 利用了 Git 的这一特性，允许用户定义一组钩子（hook），这些钩子会在提交之前自动执行

`pre-commit` 支持以下几种类型的 hook：

- pre-commit：这是最常用的一种 hook，它会在提交之前运行
- pre-push：这种 hook 会在 push 操作之前运行
- post-merge：这种 hook 会在合并分支之后运行
- prepare-commit-msg：这种 hook 会在创建提交信息时运行

## 安装和初始化

安装 CLI 工具

```bash
pipx install pre-commit
```

执行以下命令生成一个最基本的 `.pre-commit-config.yaml` 配置文件：

```bash
pre-commit sample-config > .pre-commit-config.yaml
```

确保项目中已经初始化了 Git，并且已经包含了第一份提交。运行以下命令以安装 pre-commit：

```bash
pre-commit install
```

## 离线执行

使用命令 `pip install pre-commit` 在项目中安装用于 pre-commit 的包管理器。

然后创建 `.pre-commit-config.yaml` 配置文件，类似于：

```yaml
repos:
  - repo: https://github.com/astral-sh/ruff-pre-commit
    # Ruff version.
    rev: v0.14.4
    hooks:
      # Run the linter.
      - id: ruff
        types_or: [ python, pyi, jupyter ]
        args: [ --fix ]
      # Run the formatter.
      - id: ruff-format
        types_or: [ python, pyi, jupyter ]

```

上述配置文件中包含 GitHub 仓库链接，也就是会访问 [`.pre-commit-hooks.yaml`](https://github.com/astral-sh/ruff-pre-commit/blob/main/.pre-commit-hooks.yaml)。 

如果环境无法联网，也可以这样配置：

```yaml
repos:
  - repo: local
    hooks:
      - id: ruff
        name: ruff
        entry: ruff check --force-exclude
        language: system
        types: [python]
      - id: ruff-format
        name: ruff-format
        entry: ruff format --force-exclude
        language: system
        types: [python]
      - id: docformatter
        name: docformatter
        entry: docformatter
        language: python
        args: [--in-place]
      - id: commitizen
        name: commitizen-check
        entry: cz check
        language: python
        args: [--allow-abort, --commit-msg-file]
        stages: [commit-msg]

```

最后一个 `commitizen` 比较特别，它是针对 commit message 本身进行校验，可以用 `pip install commitizen` 安装它，它将确保 commit message 符合[AngularJS commit message format](https://docs.google.com/document/d/1QrDFcIiPjSLDn3EL15IJygNPiHORgU1_OOAqWjiDU5Y/edit#) 规范。

同时还需要执行：

```bash
pre-commit install --hook-type commit-msg
```

才能实现针对 commit message 本身进行校验的功能。

具体操作过程还可以参考：[How to setup git hooks(pre-commit, commit-msg) in my project?](https://medium.com/@0xmatriksh/how-to-setup-git-hooks-pre-commit-commit-msg-in-my-project-11aaec139536)

## 官方 hooks 列表

官方提供的 hooks 列表：<https://pre-commit.com/hooks.html>

<https://waynerv.com/posts/build-automatic-code-quality-workflow>

### Python 配置

```python
# See https://pre-commit.com for more information
# See https://pre-commit.com/hooks.html for more hooks
repos:
  - repo: https://github.com/pre-commit/pre-commit-hooks
    rev: v6.0.0
    hooks:
      - id: trailing-whitespace
      - id: end-of-file-fixer
      - id: check-yaml
      - id: check-added-large-files
  - repo: https://github.com/astral-sh/ruff-pre-commit
    # Ruff version.
    rev: v0.14.4
    hooks:
      # Run the linter.
      - id: ruff-check
        args: ["--fix"]
      # Run the formatter.
      - id: ruff-format

```

### Golang 配置

