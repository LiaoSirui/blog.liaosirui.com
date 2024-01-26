

## 简介

GoReleaser 采用 Golang 开发，是一款用于 Golang 项目的自动发布工具。无需太多配置，只需要几行命令就可以轻松实现跨平台的包编译、打包和发布到 Github、Gitlab 等版本仓库

安装：<https://goreleaser.com/install/>

主页：<https://github.com/goreleaser/goreleaser>

## 初始化

```bash
goreleaser init
```

执行完上述命令后，将会在项目目录下生成 `.goreleaser.yml` 配置文件：

```yaml
# This is an example .goreleaser.yml file with some sensible defaults.
# Make sure to check the documentation at https://goreleaser.com
before:
  hooks:
    # You may remove this if you don't use go modules.
    - go mod tidy
    # you may remove this if you don't need go generate
    - go generate ./...
builds:
  - env:
      - CGO_ENABLED=0
    goos:
      - linux
      - windows
      - darwin
archives:
  - replacements:
      darwin: Darwin
      linux: Linux
      windows: Windows
      386: i386
      amd64: x86_64
checksum:
  name_template: 'checksums.txt'
snapshot:
  name_template: "{{ incpatch .Version }}-next"
changelog:
  sort: asc
  filters:
    exclude:
      - '^docs:'
      - '^test:'

```

## 获取 gitlab token

为项目打上标签

```bash
git tag -a v1.0.0 -m "release v1.0.0"

git push origin v1.0.0
```

执行自动发布流程

```bash
goreleaser --rm-dist
```

如果项目目录没有 `dist` 目录，可以不加 `--rm-dist` 参数，执行完成后将生成如下文件结构