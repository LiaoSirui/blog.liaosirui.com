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
[tool.uv.pip]
    index-url = "https://pypi.tuna.tsinghua.edu.cn/simple"
[[tool.uv.index]]
    default = true
    url     = "https://pypi.tuna.tsinghua.edu.cn/simple"

```

或者设置环境变量

```bash
export UV_DEFAULT_INDEX="https://pypi.tuna.tsinghua.edu.cn/simple"
```

添加依赖

```bash
# 添加单个包
uv add requests

# 指定版本约束
uv add 'requests==2.31.0'

# 添加 Git 依赖
uv add git+https://github.com/psf/requests

# 从 requirements.txt 文件添加所有依赖
uv add -r requirements.txt -c constraints.txt
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

更新特定包，该命令会尝试将指定包更新到最新的兼容版本，同时保持锁文件中其他依赖不变

```bash
uv sync --upgrade-package pandas
```

要从特定索引添加 Python 包，请使用 `--index` 选项

```bash
uv add torch --index pytorch=https://download.pytorch.org/whl/cpu
```

## 分组管理依赖

还有一个比较常用的功能是区分开发环境和生产环境的依赖

```bash
uv add --dev pytest
```

可以使用 `--group` 标志将开发依赖项划分为多个组

```bash
uv add --group lint ruff
```

依赖项组可以包括其他依赖项组，例如：

```toml
[dependency-groups]
dev = [
  {include-group = "lint"},
  {include-group = "test"}
]
lint = [
  "ruff"
]
test = [
  "pytest"
]
```

## 工具管理

uv 可以在隔离的虚拟环境中安装命令行工具，并无需显式安装即可执行一次性命令

可以替代 pipx 等工具来运行和管理 Python 工具

```bash
uv tool install

# 别名 uvx
uv tool run
```

比如

```bash
uvx ruff check
```

可以使用 `@` 语法指定工具的版本：

```bash
# 运行特定版本的工具
uvx ruff@0.1.5 check .

# 运行最新版本的工具
uvx ruff@latest check .
```

也可以使用 `--from` 选项指定更复杂的版本约束：

```bash
# 指定版本范围
uvx --from 'ruff>0.2.0,<0.3.0' ruff check .
```

可以使用 `--with` 选项添加额外的依赖或插件：

```bash
# 运行带插件的工具
uvx --with mkdocs-material mkdocs serve

# 安装带插件的工具
uv tool install mkdocs --with mkdocs-material

```

## 管理 Python 版本

uv 可以轻松管理多个 Python 版本，无需额外安装 pyenv 等工具

查看可用的 Python 版本：

```bash
uv python list
```

安装特定版本的 Python：

```bash
# 安装最新的 Python 3.13
uv python install 3.13

# 安装特定版本
uv python install 3.13.9

```

初始化一个新的虚拟环境：

```bash
# 创建虚拟环境，不加环境路径的话默认是保存在当前的.venv目录下
uv venv 

# 指定环境保存目录
uv venv /path/to/venv

# 指定 Python 版本，注意需要对应版本的 Python 已经安装
uv venv -p 3.14

# --python 同 -p
uv venv --python 3.14
```

## Git 仓库依赖

### 使用 uv 管理 Git 仓库依赖

uv 的 Git 集成能力源自 uv-git 与 uv-git-types 两个核心模块

通过 uv 安装 Git 仓库依赖与常规包管理同样简单。在终端中执行：

```bash
# 安装特定Git仓库
uv add git+https://github.com/akfamily/akshare.git
 
# 指定分支
uv add git+https://github.com/akfamily/akshare.git@main
 
# 指定 tag
uv add git+https://github.com/akfamily/akshare.git@release-v1.17.83
 
# 指定 commit hash
uv add git+https://github.com/akfamily/akshare.git@fc221438791f4977657b938b05dc7d0fa118a536
```

uv 会自动执行以下操作：

1. 解析 Git URL 并验证仓库可访问性
2. 执行增量克隆（仅获取必要历史）
3. 检出指定版本
4. 构建并安装包
5. 缓存结果以加速后续安装

最终生成的配置

```bash
[project]
    dependencies    = ["akshare"]

[tool.uv.sources]
    akshare = { git = "https://github.com/akfamily/akshare.git", rev = "release-v1.17.83" }

```



对于项目依赖，推荐在 `pyproject.toml` 中显式声明 Git 依赖：

```toml
[project]
name = "my-project"
version = "0.1.0"
dependencies = [
  # 基础 Git 依赖
  "akshare @ git+https://github.com/akfamily/akshare.git",
  # 带子目录的依赖
  "nested-package @ git+https://gitcode.com/org/repo.git#subdirectory=packages/nested",
  # 带额外功能的依赖
  "full-package[extra] @ git+ssh://git@gitcode.com:org/repo.git@dev-branch",
]
```

声明后执行 `uv sync` 即可安装所有依赖

### 私有仓库认证

uv 通过 uv-auth 模块提供全面的认证支持：

- SSH 密钥认证：自动使用系统 SSH 密钥链
- HTTPS 令牌认证：支持环境变量注入 
- 系统密钥链

配置

```toml
# ~/.config/uv/uv.toml
[auth]
"gitcode.com" = { username = "myuser", password = "mytoken" }
"gitlab.company.com" = { ssh_key_path = "~/.ssh/id_rsa_company" }

```

使用环境变量

```bash
export UV_HTTPS_AUTH=gitcode.com:username:token
```

若遇到认证失败，可通过以下步骤排查

```bash
UV_LOG=uv_git=debug uv sync
```

### 依赖解析策略

uv 提供两种 Git 依赖解析策略，可通过 `tool.uv.resolver.git-strategy` 配置：

```toml
[tool.uv.resolver]
# 快速模式（默认）：仅获取必要提交，最快但不支持本地修改
git-strategy = "shallow"

# 完整模式：克隆完整仓库，支持本地开发
git-strategy = "full"

```

### 工作区支持

对于包含多个包的 Git 仓库，uv 支持通过 subdirectory 参数安装特定子目录：

```toml
dependencies = [
  "package-a @ git+https://gitcode.com/org/monorepo.git#subdirectory=packages/a",
  "package-b @ git+https://gitcode.com/org/monorepo.git#subdirectory=packages/b@v2.0",
]

```

### 缓存管理

uv 会将 Git 仓库缓存到 `~/.cache/uv/git-v0` 目录，可通过以下命令管理缓存：

```bash
# 查看缓存目录
uv cache dir
 
# 清理过期缓存
uv cache clean --git
 
# 强制刷新特定仓库
uv add --refresh git+https://github.com/akfamily/akshare.git
```

## 依赖冲突处理

可以尝试使用 uv 的依赖覆盖功能

```toml
[tool.uv]
override-dependencies = [
  "requests>=2.26"
]

```

