## Nox

Nox 是另一个非常棒的自动化测试工具

文档：

- <https://nox.thea.codes/en/stable/>

与 tox 不同，Nox 使用标准的 Python 文件进行配置。在 Nox 中使用 PDM 更加容易，下面是 noxfile.py 的一个示例：

```python
import os
import nox

os.environ.update({"PDM_IGNORE_SAVED_PYTHON": "1"})

@nox.session
def tests(session):
    session.run_always('pdm', 'install', '-G', 'test', external=True)
    session.run('pytest')

@nox.session
def lint(session):
    session.run_always('pdm', 'install', '-G', 'lint', external=True)
    session.run('flake8', '--import-order-style', 'google')
```

