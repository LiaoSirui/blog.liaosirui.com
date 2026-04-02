## 管理 Python 版本

uv 可以轻松管理多个 Python 版本，无需额外安装 pyenv 等工具

查看可用的 Python 版本：

```bash
uv python list
```

查看已经安装的 python

```bash
uv python list --only-installed
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
