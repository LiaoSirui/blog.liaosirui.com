## Tox

Tox 可以针对多个 Python 版本或依赖集进行测试

文档：

- <https://tox.readthedocs.io/en/latest/>
- <https://github.com/pdm-project/tox-pdm>

## 集成 Tox 到 PDM

可以配置一个像下面这样的 tox.ini 来将测试与 PDM 集成起来：

```ini
[tox]
env_list = py{36,37,38},lint

[testenv]
setenv =
    PDM_IGNORE_SAVED_PYTHON="1"
deps = pdm
commands =
    pdm install --dev
    pytest tests

[testenv:lint]
deps = pdm
commands =
    pdm install -G lint
    flake8 src/
```

为了摆脱这些限制，有一个名为 tox-pdm 的 Tox 插件，可以简化使用方式

```bash
pdm add --dev tox-pdm
```

可以将 tox.ini 设置得更加整洁，如下所示：

```ini
[tox]
env_list = py{36,37,38},lint

[testenv]
groups = dev
commands =
    pytest tests

[testenv:lint]
groups = lint
commands =
    flake8 src/

```

