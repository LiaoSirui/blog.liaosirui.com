## 简介

`PDM` 全名 `Python Development Master`

官方：

- GitHub 仓库：<https://github.com/pdm-project/pdm>
- 官网：<https://pdm.fming.dev/latest/>

## 安装方式

```bash
pip install pdm
```

## 使用

### 初始化项目

使用 `PDM` 初始化项目很简单，只需要创建一个文件夹，然后进入文件夹中执行 `pdm init` 命令即可完成初始化

```bash
pdm init
```

初始化完成后项目中会生成`.pdm.toml`、`pyproject.toml` 两个模板文件，而主要关注`pyproject.toml`

### 给项目添加依赖包

和大多数的包管理工具一样，`PDM` 也是用 `add` 指令。

添加 `requests` 的过程：

```bash
pdm add request
```

和 Poetry 一样，安装使用的是 add 命令，但 pdm 的 add 比 poetry 好用，主要体现在分组

### 查看项目依赖包

使用 `pdm list` 可以以列表形式列出当前环境已安装的包：

```bash
pdm list
```

再加个 `--graph` 就能以树状形式查看，直接依赖包和间接依赖包关系的层级一目了然

pdm list 还有两个选项：

- `--freeze`：以 `requirements.txt` 的格式列出已安装的包
- `--json`：以 `json` 的格式列出已安装的包，但必须与 `--graph` 同时使用

要查看某个包的某体详情，直接用 `pdm show` 即可

### 对于已有的项目进行初始化

执行命令

```bash
pdm install
```

## 配置多个源

官方文档地址：<https://pdm.fming.dev/1.15/pyproject/tool-pdm/#specify-other-sources-for-finding-packages>

多个源的配置示例：

```toml
[tool.pdm]
    [[tool.pdm.source]]
        name       = "pypi"
        url        = "http://devpi.local.liaosirui.com:3141/root/douban/+simple/"
        verify_ssl = true
    [[tool.pdm.source]]
        name       = "torch-cu116"
        url        = "http://devpi.local.liaosirui.com:3141/root/torch-cu116/+simple/"
        verify_ssl = false

```

## 方案兼容

### 其他方案迁移到 pdm

如果当前使用的是其他的包管理器，比如 pipenv ，poetry，或者还在用最原始的 requirements.txt ，也可以很方便的迁移到 pdm 中来：

- 使用 `pdm import -f {file}` 无需初始化，直接转换

- 执行 `pdm init` 或者 `pdm install `的时候，会自动识别当前的依赖情况并转换

### pdm 迁移到其他方案

可以将 pdm 管理的项目，导出为其他方案

- 将 pyproject.toml 转成 setup.py（暂未支持，<https://pdm.fming.dev/latest/usage/project/#export-locked-packages-to-alternative-formats>）

```bash
pdm export -f setuppy -o setup.py
# pdm export -f setuppy -o setup.py --without-hashes --pyproject --prod
```

- 将 pdm.lock 转成 requirements.txt

```bash
pdm export -o requirements.txt
```

