## isort 简介

isort 是一个 Python 的实用程序 / 库，它会按字母顺序对导入 (import) 的库进行排序，并自动分组。它提供多种使用方式，包括命令行、Python 调用等

![isort your imports, so you don't have to.](.assets/isort/python_isort_logo_large.png)

官方：

- GitHub 仓库：<https://github.com/PyCQA/isort>
- 官方文档：<https://pycqa.github.io/isort/>

在使用 isort 格式化 import 之前，代码可能是长这样的：

```python
from my_lib import Object
import os
from my_lib import Object3
from my_lib import Object2
import sys
from third_party import lib15, lib1, lib2, lib3, lib4, lib5, lib6, lib7, lib8, lib9, lib10, lib11, lib12, lib13, lib14
import sys
from __future__ import absolute_import
from third_party import lib3
print("Hey")
print("yo")
```

使用 isort 格式化后的代码：

```python
from __future__ import absolute_import

import os
import sys

from my_lib import Object, Object2, Object3
from third_party import (lib1, lib2, lib3, lib4, lib5, lib6, lib7, lib8, lib9,
                         lib10, lib11, lib12, lib13, lib14, lib15)

print("Hey")
print("yo")

```

杂乱无章的格式瞬间变得井然有序

## isort 使用

### 安装 isort

使用 pip 或者 pipx 进行安装

```bash
pip install isort

pipx install isort
```

如果需要支持对 requirements.txt 的整理

```bash
pip install isort[requirements_deprecated_finder]

pipx install isort[requirements_deprecated_finder]
```

带 Pipfile 支持的 isort 安装：

```bash
pip install isort[pipfile_deprecated_finder]

pipx install isort[pipfile_deprecated_finder]
```

支持两种格式的 isort 安装：

```
pip install isort[requirements_deprecated_finder,pipfile_deprecated_finder]

pipx install isort[requirements_deprecated_finder,pipfile_deprecated_finder]
```

### 调用方式

isort 有 2 种使用方法，一种是从命令行直接针对 py 文件进行整理、另一种是在 Python 内导入 isort 进行整理

- 命令行整理

要在特定文件上运行 isort，请在命令行执行以下操作：

```javascript
isort mypythonfile.py mypythonfile2.py

# or:
python -m isort mypythonfile.py mypythonfile2.py
```

要对本文件夹递归进行 isort 整理，请执行以下操作：

```javascript
isort .

# or:
python -m isort .
```

要查看更改建议的而不直接应用它们，请执行以下操作：

```javascript
isort mypythonfile.py --diff
```

如果要对项目自动运行 isort，但是希望仅在未引入语法错误的情况下应用更改：

```javascript
isort --atomic .
```

> 注意：默认情况下这是禁用的，因为它可以防止 isort 针对使用不同版本的 Python 编写的代码运行

- 从 Python 内部

```python
import isort


isort.file("pythonfile.py")
```

或者：

```python
import isort


sorted_code = isort.code("import b\nimport a\n")
```

### 智能平衡格式化

从 isort 3.1.0 开始，添加了对平衡多行导入的支持。启用此选项后，isort 将动态地将导入长度更改为生成最平衡网格的长度，同时保持低于定义的最大导入长度

开启了平衡导入的格式化：

```python
from __future__ import (absolute_import, division,
                        print_function, unicode_literals)
```

未开启平衡的格式化：

```python
from __future__ import (absolute_import, division, print_function,
                        unicode_literals)
```

要启用此设置， 在你的配置设置 `balanced_wrapping = True` 或通过命令行添加 `-e`  参数执行整理

### 跳过某个 import

要使 isort 忽略单个 import，只需在包含文本的导入行的末尾添加注释 `isort:skip` ，如下：

```python
import module # isort:skip
```

或者：

```python
from xyz import (abc, # isort:skip
                 yo,
                 hey)
```

要使 isort 跳过整个文件，只需添加 `isort:skip_file` 到文件的开头注释中：

```python
"""
my_module.py
Best module ever

isort:skip_file
"""

import b
import a
```

## vscode 插件

官方地址：<https://marketplace.visualstudio.com/items?itemName=ms-python.isort>

直接配置

```json
{
    "[python]": {
        "editor.defaultFormatter": "ms-python.black-formatter",
        "editor.formatOnSave": true,
        "editor.codeActionsOnSave": {
            "source.organizeImports": true
        }
    },
    "isort.args": [
        "-e",
        "--profile",
        "black"
    ],
    "isort.path": [
        "isort"
    ]
}

```

## 参考链接

- <https://muzing.top/posts/38b1b99e/>
- Black <https://muzing.top/posts/a29e4743/>