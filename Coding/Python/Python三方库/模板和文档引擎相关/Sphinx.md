## 简介

Sphinx 是 Python 文档生成器，它基于 reStructuredText 标记语言，可自动根据项目生成 HTML ，PDF 等格式的文档，无数著名项目的文档均用Sphinx生成，如机器学习库 scikit-learn 、交互式神器 Jupyter Notebook

- <https://www.osgeo.cn/sphinx/index.html>
- <https://docutils.sourceforge.io/rst.html>

安装

```bash
pipx install sphinx
```

## 快速入门

在 src layout 中，doc 目录用来存放 sphinx 自动生成的文件

命令行进入 doc 目录`cd doc`

执行命令`sphinx-quickstart`，设置结构分离、项目名、作者名、版本号、语言（配置后面可修改）

```bash
> Separate source and build directories (y/n) [n]: y
> Project name: AlphaQuant Data API SDK
> Author name(s): LiaoSirui
> Project release []: 1.0
> Project language [en]: zh_cn

```

在`doc/source/conf.py`指定项目代码路径

```bash
import os
import sys
sys.path.insert(0, os.path.abspath('../../src'))

```

在 `doc/source/conf.py` 修改 [extensions](https://www.osgeo.cn/sphinx/usage/extensions/index.html)，添加功能

- 包括注释中的文档
- 支持 NumPy 和 Google 风格
- 包括测试片段
- 链接到其他项目的文档
- TODO 项
- 文档覆盖率统计
- 通过 javascript 呈现数学公式
- ..等等

```python
extensions = [
    "sphinx.ext.autodoc",
    "sphinx.ext.doctest",
    "sphinx.ext.todo",
    "sphinx.ext.autosummary",
    "sphinx.ext.extlinks",
    "sphinx.ext.intersphinx",
    "sphinx.ext.viewcode",
    "sphinx.ext.inheritance_diagram",
    "sphinx.ext.coverage",
    "sphinx.ext.graphviz",
    "sphinx.ext.mathjax",
    "sphinx.ext.napoleon",
]
```

命令行进入doc目录，执行生成API文档命令`sphinx-apidoc -o source ../src/`

生成 HTML`make html`

打开`build/html/reStructredText.html`

重新生成
- 项目代码未变更

在 doc下执行命令 `make clean` 和 `make html`（直接也行）

- 项目代码已变更

删除 `doc/build`下的所有文件夹

删除 `doc/source` 下除 `index.rst` 的所有 `.rst`文件

在 doc 下执行命令`sphinx-apidoc -o source ../src/` 和 `make html`

## 切换主题

1. 安装主题`pip install sphinx_rtd_theme`
2. 修改`doc/source/conf.py`的`html_theme`

```python
html_theme = 'sphinx_rtd_theme'
```

## 注释风格

- reStructuredText 注释规范文档：<https://learn-rst.readthedocs.io/zh_CN/latest/index.html>
- numpy 注释规范文档：<https://numpydoc.readthedocs.io/en/latest/format.html#docstring-standard>
- google 注释规范文档：<https://google.github.io/styleguide/pyguide.html>

## 参考资料

- <https://blog.hszofficial.site/recommend/2020/11/27/%E4%BD%BF%E7%94%A8Sphinx%E5%86%99%E9%A1%B9%E7%9B%AE%E6%96%87%E6%A1%A3/>