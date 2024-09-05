## GitHub Actions

GitHub Actions 是一种持续集成和持续交付 (CI/CD) 平台，可用于自动执行生成、测试和部署管道

官方文档：

- <https://github.com/features/actions>

- <https://docs.github.com/zh/actions/learn-github-actions/understanding-github-actions>

官方市场：<https://github.com/marketplace?type=actions>

参考：

- <https://github.com/sdras/awesome-actions>

## 基本概念

- workflow （工作流程）：持续集成一次运行的过程，就是一个 workflow

- job （任务）：一个 workflow 由一个或多个 jobs 构成，含义是一次持续集成的运行，可以完成多个任务

- step（步骤）：每个 job 由多个 step 构成，一步步完成

- action （动作）：每个 step 可以依次执行一个或多个命令（action）

### workflow 文件

GitHub Actions 的配置文件叫做 workflow 文件，存放在代码仓库的 `.github/workflows` 目录

workflow 文件采用 YAML 格式，文件名可以任意取，但是后缀名统一为 `.yml`，比如`foo.yml`

一个库可以有多个 workflow 文件，GitHub 只要发现 `.github/workflows` 目录里面有 `.yml` 文件，就会自动运行该文件

下面是一个完整的 workflow 文件的范例

```yaml
name: Greeting from Mona
on: push

jobs:
  my-job:
    name: My Job
    runs-on: ubuntu-latest
    steps:
    - name: Print a greeting
      env:
        MY_VAR: Hi there! My name is
        FIRST_NAME: Mona
        MIDDLE_NAME: The
        LAST_NAME: Octocat
      run: |
        echo $MY_VAR $FIRST_NAME $MIDDLE_NAME $LAST_NAME.
```

构建镜像示例

```yaml
name: Docker Image CI

on:
  push:
    branches: [ "main", "master" ]

permissions:
  contents: read
  packages: write

jobs:
  release:
    runs-on: ubuntu-latest
    steps:
      - name: Clone repo
        uses: actions/checkout@v4
        with:
          submodules: recursive
      - name: Setup QEMU
        uses: docker/setup-qemu-action@v3
      - name: Setup Docker Buildx
        id: buildx
        uses: docker/setup-buildx-action@v3
      - name: Login to GitHub Container Registry
        uses: docker/login-action@v3
        with:
          registry: ghcr.io
          username: ${{ github.repository_owner }}
          password: ${{ secrets.GITHUB_TOKEN }}
      - name: Prepare
        id: prep
        run: |
          VERSION=sha-${GITHUB_SHA::8}
          if [[ $GITHUB_REF == refs/tags/* ]]; then
            VERSION=${GITHUB_REF/refs\/tags\//}
          fi
          echo "VERSION=${VERSION}" >> $GITHUB_OUTPUT
      - name: Generate images meta
        id: meta
        uses: docker/metadata-action@v5
        with:
          images: ghcr.io/liaosirui/blog-liaosirui-com
          tags: type=raw,value=${{ steps.prep.outputs.VERSION }}
      - name: Publish multi-arch image
        uses: docker/build-push-action@v5
        id: build
        with:
          push: true
          builder: ${{ steps.buildx.outputs.name }}
          context: .
          file: ./Dockerfile
          platforms: linux/amd64
          tags: ghcr.io/liaosirui/blog-liaosirui-com:${{ steps.prep.outputs.VERSION }}
          labels: ${{ steps.meta.outputs.labels }}

```

