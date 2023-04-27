## 镜像

### Python 镜像推荐设置的环境变量

Python 中推荐的常见环境变量如下：

```dockerfile
# 设置环境变量
ENV PYTHONDONTWRITEBYTECODE 1
ENV PYTHONUNBUFFERED 1
```

1. `ENV PYTHONDONTWRITEBYTECODE 1`: 建议构建 Docker 镜像时一直为 `1`, 防止 python 将 pyc 文件写入硬盘
2. `ENV PYTHONUNBUFFERED 1`: 建议构建 Docker 镜像时一直为 `1`, 防止 python 缓冲 (buffering) stdout 和 stderr, 以便更容易地进行容器日志记录

参考：<https://docs.python.org/3/using/cmdline.html>

### 使用非 root 用户运行容器进程

出于安全考虑，推荐运行 Python 程序前，创建 非 root 用户并切换到该用户。

```dockerfile
# 创建一个具有明确 UID 的非 root 用户，并增加访问 /app 文件夹的权限。
RUN adduser -u 5678 --disabled-password --gecos "" appuser && chown -R appuser /app

USER appuser
```

### 使用 `.dockerignore` 排除无关文件

需要排除的无关文件一般如下：

```dockerfile

**/__pycache__
**/*venv
**/.classpath
**/.dockerignore
**/.env
**/.git
**/.gitignore
**/.project
**/.settings
**/.toolstarget
**/.vs
**/.vscode
**/*.*proj.user
**/*.dbmdl
**/*.jfm
**/bin
**/charts
**/docker-compose*
**/compose*
**/Dockerfile*
**/node_modules
**/npm-debug.log
**/obj
**/secrets.dev.yaml
**/values.dev.yaml
*.db
.python-version
LICENSE
README.md
```

这里选择几个说明下：

1. `**/__pycache__`: python 缓存目录
2. `**/*venv`: Python 虚拟环境目录。很多 Python 开发习惯将虚拟环境目录创建在项目下，一般命名为：`.venv` 或 `venv`
3. `**/.env`: Python 环境变量文件
4. `**/.git` `**/.gitignore`: git 相关目录和文件
5. `**/.vscode`: 编辑器、IDE 相关目录
6. `**/charts`: Helm Chart 相关文件
7. `**/docker-compose*`: docker compose 相关文件
8. `*.db`: 如果使用 sqllite 的相关数据库文件
9. `.python-version`: pyenv 的 .python-version 文件

### 不建议使用 Alpine 作为 Python 的基础镜像

大多数 Linux 发行版使用 GNU 版本（glibc）的标准 C 库，几乎每个 C 程序都需要这个库，包括 Python。

但是 Alpine Linux 使用 musl, Alpine 禁用了 Linux wheel 支持。

理由如下：


- 缺少大量依赖
- CPython 语言运行时的相关依赖
- openssl 相关依赖
- libffi 相关依赖
- gcc 相关依赖
- 数据库驱动相关依赖
- pip 相关依赖
- 构建可能更耗时
- Alpine Linux 使用 musl，一些二进制 wheel 是针对 glibc 编译的，但是 Alpine 禁用了 Linux wheel 支持。现在大多数 Python 包都包括 PyPI 上的二进制 wheel，大大加快了安装时间。但是如果使用 Alpine Linux，可能需要编译使用的每个 Python 包中的所有 C 代码。
- 基于 Alpine 构建的 Python 镜像反而可能更大

建议使用官方的 python slim 镜像作为基础镜像

镜像库：https://hub.docker.com/_/python

使用官方 python slim 的理由还包括：


- 稳定性
- 安全升级更及时
- 依赖更新更及时
- 依赖更全
- Python 版本升级更及时
- 镜像更小

### Python 镜像构建不需要使用"多阶段构建"

一般情况下，Python 镜像构建不需要使用"多阶段构建".

理由如下：

- Python 没有像 Golang 一样，可以把所有依赖打成一个单一的二进制包
- Python 也没有像 Java 一样，可以在 JDK 上构建，在 JRE 上运行
- Python 复杂而散落的依赖关系，在"多阶段构建"时会增加复杂度
- ...

如果有一些特殊情况，可以尝试使用"多阶段构建"压缩镜像体积：


- 构建阶段需要安装编译器
- Python 项目复杂，用到了其他语言代码（如 C/C++/Rust)

### pip 小技巧

使用 pip 安装依赖时，可以添加 `--no-cache-dir` 减少镜像体积：

```bash
# 安装 pip 依赖
COPY requirements.txt .
RUN python -m pip install --no-cache-dir --upgrade -r requirements.txt
```

## 示例

```dockerfile
FROM python:3.10-slim

LABEL maintainer="cyril@liaosirui.com"

EXPOSE 8000

# Keeps Python from generating .pyc files in the container
ENV PYTHONDONTWRITEBYTECODE=1

# Turns off buffering for easier container logging
ENV PYTHONUNBUFFERED=1

# Install pip requirements
COPY requirements.txt .
RUN python -m pip install --no-cache-dir --upgrade -r requirements.txt

WORKDIR /app
COPY . /app

# Creates a non-root user with an explicit UID and adds permission to access the /app folder
RUN adduser -u 5678 --disabled-password --gecos "" appuser && chown -R appuser /app
USER appuser

CMD ["uvicorn", "main:app", "--host", "0.0.0.0"]
```

