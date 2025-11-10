## Ruff

基于 Rust 编写的高性能 Python 代码分析工具（即 Linter），用于检查代码中的语法错误、编码规范问题、潜在的逻辑问题和代码质量问题

All-in-One Linter & Formatter for Python，替换 Black/Flake8/autopep8/isort 等

Ruff 的配置也很简单，支持在 `pyproject.toml` 或 `ruff.toml` 中配置

```toml
[tool.ruff]
line-length = 120  # 代码最大行宽
select = [         # 选择的规则
    "F",
    "E",
    "W",
    "UP",
]
ignore = ["F401"]  # 忽略的规则

```

| 标识 | 规则                         | 简介                           |
| ---- | ---------------------------- | ------------------------------ |
| F    | pyflakes                     | 提供了一些比较基础的问题检查。 |
| E,W  | pycodestyle errors, warnings | PEP8 检查。                    |
| I    | isort                        | 对 import 语句进行排序。       |
| UP   | pyupgrade                    | 提示新版本的 Python 语法。     |
| N    | pep8-naming                  | PEP8 命名规范检查。            |
| PL   | Pylint                       | 知名静态代码检查器。           |
| PERF | pyperf                       | 检测一些性能问题。             |
| RUF  | Ruff                         | Ruff 社区自己实现的一些规则。  |

VSCode 配置：

- Flake8: 与 Ruff 重复，参见 [How does Ruff's linter compare to Flake8?](https://link.zhihu.com/?target=https%3A//docs.astral.sh/ruff/faq/%23how-does-ruffs-linter-compare-to-flake8)
- isort: 与 Ruff 重复，参见 [How does Ruff's linter compare to Flake8?](https://link.zhihu.com/?target=https%3A//docs.astral.sh/ruff/faq/%23how-does-ruffs-linter-compare-to-flake8)
- Black Formatter：与 Ruff 重复，参见 [Is the Ruff linter compatible with Black?](https://link.zhihu.com/?target=https%3A//docs.astral.sh/ruff/faq/%23is-the-ruff-linter-compatible-with-black)
- Pylint：与 Pylance 重复，参见 [Pylance 文档](https://link.zhihu.com/?target=https%3A//marketplace.visualstudio.com/items%3FitemName%3Dms-python.vscode-pylance)

