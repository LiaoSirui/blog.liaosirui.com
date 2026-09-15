## 简介

g（Golang Version Manager） 就是在官方的 golang/dl 上包了一层。

官方：

- Github 仓库：<https://github.com/voidint/g>
- 最新版本：<https://github.com/voidint/g/releases>

## 安装

建议安装前清空 `GOROOT`、`GOBIN` 等环境变量。

将压缩包解压至 `PATH` 环境变量目录下（推荐 `~/.g/bin` 目录）

```bash
mkdir -p ~/.g/bin
export I_G_VERSION=v1.5.0
cd $(mktemp -d)
curl -sL https://github.com/voidint/g/releases/download/${I_G_VERSION}/g${I_G_VERSION/v/}.linux-amd64.tar.gz -o g.tgz
tar zxvf g.tgz -C ~/.g/bin
```

将所需的环境变量写入`~/.g/env`文件

```bash
cat > ~/.g/env <<'EOF'
#!/bin/sh
# g shell setup
export GOROOT="${HOME}/.g/go"
export GOBIN="${GOROOT}/bin"
export PATH="${HOME}/.g/bin:${GOROOT}/bin:$PATH"
export G_MIRROR=https://golang.google.cn/dl/
EOF
```

将 `~/.g/env` 导入到 shell 环境配置文件（如 `~/.bashrc`、`~/.zshrc`...）

```bash
cat >> ~/.zshrc <<'EOF'
export GO111MODULE="auto"
export GOPROXY=https://goproxy.cn,direct
export GOCACHE=/var/cache/go-build

alias g=~/.g/bin/g
# g shell setup
if [ -f "${HOME}/.g/env" ]; then
    . "${HOME}/.g/env"
fi
EOF
```

启用环境变量

```bash
source ~/.zshrc # 或 source ~/.bashrc
```

## 使用

获取到现在官方支持的所有 golang 版本。这些其实都是 dl 提供的支持。

```bash
g ls-remote
```

使用 `g install 1.19.5` 安装想要安装的远端支持的版本

```bash
> g install 1.19.5
Downloading 100% [===============] (142/142 MB, 8.9 MB/s)
Computing checksum with SHA256
Checksums matched
Now using go1.19.5
```

使用 `g ls` 就可以看到本地已经安装的 golang 版本

```bash
> g ls
* 1.19.5
```

使用 `g use` 就可以选择想要使用的版本进行切换

```bash
> g use 1.19.5
```

