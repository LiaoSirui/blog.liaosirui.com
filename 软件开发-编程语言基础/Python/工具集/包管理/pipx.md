## pipx

pipx 是安装并运行 Python 终端用户应用（end-user applications）的工具

将 Python 包安全地安装在隔离环境中，同时又可以全局暴露出命令行的调用入口

这样可以避免依赖之间的冲突

官方：

- GitHub 仓库：<https://github.com/pypa/pipx>
- 文档：<https://pypa.github.io/pipx/>

## 使用

### 环境变量

```bash
  PIPX_HOME             Overrides default pipx location. Virtual Environments
                        will be installed to $PIPX_HOME/venvs.
  PIPX_BIN_DIR          Overrides location of app installations. Apps are
                        symlinked or copied here.
  PIPX_DEFAULT_PYTHON   Overrides default python used for commands.
  USE_EMOJI             Overrides emoji behavior. Default value varies based
                        on platform.
```

`pipx` 二进制文件的默认位置是 `~/.local/bin`；可以使用 `PIPX_BIN_DIR` 环境变量覆盖它

### 升级包

要升级包，只需执行以下操作：

```text
pipx upgrade cowsay
```

要一次性升级所有已安装的软件包，请使用：

```text
pipx upgrade-all
```

### 从临时虚拟环境运行应用

有时，可能希望运行特定的 Python 程序，但并不实际安装它

```text
pipx run pycowsay moooo
```

### 卸载软件包

可以使用以下命令卸载软件包：

```text
pipx uninstall cowsay
```

要删除所有已安装的包：

```text
pipx uninstall-all
```

## 常用工具

有一些常用的 Python 工具，推荐尝试通过 pipx 安装：

```bash
# IT automation
pipx install ansible

# Record and share your terminal sessions, the rightway.
pipx run asciinema

# uncompromising Python code formatter
pipx run black

# internationalizing and localizing Python applications
pipx run --spec=babel pybabel --help

# detect file encoding
pipx run --spec=chardet chardetect --help

# creates projects from project templates
pipx run cookiecutter

# easily create and publish new Python packages
pipx run create-python-package

# tool for style guide enforcement
pipx run flake8

# browser-based gdb debugger
pipx run gdbgui

# create hexagon stickers automatically
pipx run hexsticker

# powerful interactive Python shell
pipx run ipython

# web-based notebook environment for interactive computing
pipx run jupyter

# python dependency/environment management
pipx run pipenv

# python dependency/environment/packaging management
pipx run poetry

# source code analyzer
pipx run pylint

# bundles a Python application and all its dependencies into a single package
pipx run pyinstaller

# fully functional terminal in the browser
pipx run pyxtermjs

# Functional programming tools for the shell
pipx install shell-functools
```

