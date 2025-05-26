## 安装 uv

uv 是由 Astral 公司开发的一个极其快速的 Python 包管理器，完全用 Rust 编写

安装 uv

```bash
pipx install uv
```

## 初始化项目和依赖管理

初始化项目

```bash
uv init
```

如果想使用 src layout 则

```bash
uv init --lib
```

完整的示例

```bash
uv init --lib --description "DataSource SDK" --author-from git --vcs git --no-pin-python
```

uv 更换源

```toml
[[tool.uv.index]]
    default = true
    url     = "https://pypi.tuna.tsinghua.edu.cn/simple"

```

添加依赖

```bash
uv add "pandas>=2.2.3,<2.3.0"
```

通过`uv run`可以直接在项目环境中执行命令，无需手动激活虚拟环境

同步项目依赖

```bash
uv sync
```

更新依赖

```bash
uv sync --upgrade
```

更新特定包

```bash
uv sync --upgrade-package pandas
```

## 工具管理

uv 可以在隔离的虚拟环境中安装命令行工具，并无需显式安装即可执行一次性命令

```bash
uv tool install

# 别名 uvx
uv tool run
```

比如

```bash
uvx ruff check
```

