## 官方 hooks 列表

官方提供的 hooks 列表：<https://pre-commit.com/hooks.html>

<https://waynerv.com/posts/build-automatic-code-quality-workflow>

```yaml
# See https://pre-commit.com for more information
# See https://pre-commit.com/hooks.html for more hooks
exclude: ".*(_pb2|_pb2_grpc).py"
repos:
  - repo: https://github.com/pre-commit/pre-commit-hooks
    rev: v4.3.0
    hooks:
      - id: trailing-whitespace
      - id: end-of-file-fixer
      - id: check-yaml
        args:
          - "--unsafe"
      - id: check-added-large-files
  - repo: https://github.com/PyCQA/autoflake
    rev: v1.7.1
    hooks:
      - id: autoflake
        args:
          - "--in-place"
          - "--ignore-init-module-imports"
          - "--expand-star-imports"
          - "--remove-duplicate-keys"
          - "--remove-unused-variables"
  # # --src-path 参数暂时没法配置成每个人本地目录通用的，所以暂时不启用
  # - repo: https://github.com/pycqa/isort
  #   rev: 5.10.1
  #   hooks:
  #     - id: isort
  #       name: isort (python)
  #       args:
  #         - "--profile"
  #         - "black"
  #         - "--filter-files"
  #         - "--trailing-comma"
  #         - "--line-length"
  #         - "160"
  - repo: https://github.com/psf/black
    rev: 22.10.0
    hooks:
      - id: black
        # It is recommended to specify the latest version of Python
        # supported by your project here, or alternatively use
        # pre-commit's default_language_version, see
        # https://pre-commit.com/#top_level-default_language_version
        language_version: python3.8
        args:
          - "--line-length"
          - "160"
  - repo: https://github.com/pycqa/flake8
    rev: 5.0.4
    hooks:
      - id: flake8
        args:
          - "--max-line-length"
          - "160"
          - "--ignore"
          - "F401" # ignore imported but unused issue for __init__.py file
  # # mypy 的 exclude 排除指定文件/目录有点问题，暂时不启用
  # - repo: https://github.com/pre-commit/mirrors-mypy
  #   rev: "v0.982"
  #   hooks:
  #     - id: mypy

```

## Golang 配置

## Python 配置
