## Peotry 简介

官方：

-  官网：<https://python-poetry.org/>
- GitHub 仓库：<https://github.com/python-poetry/poetry>

## 基本使用

### 新建项目

是在一个已有的项目里使用 Poetry，你只需要执行 poetry init 命令来创建一个 pyproject.toml 文件：

```bash
poetry init
```

如果想创建一个新的 Python 项目，使用 `poetry new <文件夹名称>` 命令可以创建一个项目模板：

```bash
poetry new poetry-demo
```

创建的项目结构如下

```bash
poetry-demo
├── pyproject.toml
├── README.rst
├── poetry_demo
│   └── __init__.py
└── tests
    ├── __init__.py
    └── test_poetry_demo.py
```

### 安装依赖

### 添加依赖

使用 poetry add 命令创建虚拟环境
