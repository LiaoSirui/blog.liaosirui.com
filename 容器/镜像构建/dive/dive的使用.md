
## 简介

用 `docker inspect` 命令可以查看一个 docker 镜像的 meta 信息，用 `docker history` 命令可以了解一个镜像的构建历史，但是这些信息对我们去分析一个镜像的具体一层的组成来说还是不太够，不够清晰明了

```text
> docker inspect python:3.6.4
[
    {
        ......
        "RootFS": {
            "Type": "layers",
            "Layers": [
                "sha256:8fad67424c4e7098f255513e160caa00852bcff347bc9f920a82ddf3f60229de",
                "sha256:86985c679800f423275a0ea3ad540e9b7f522dcdcd65ec2b20f407996162f2e0",
                "sha256:6e5e20cbf4a7246b94f7acf2a2ceb2c521e95daca334dd1e8ba388fa73443dfe",
                "sha256:ff57bdb79ac820da132ad1fdc1e2d250de5985b264dbdf60aa4ce83a05c4da75",
                "sha256:6e1b48dc2cccd7c0faf316e5975f1a02f5897723d7fa3b0367b28a20173931d6",
                "sha256:325a22db58ea59d76568ded2fac6b783554f8cd5fa8e851c260da4b141c55c6c",
                "sha256:a4a7a3673769ce5035e06f56458cab872bb5dc561bebe3571ac62fe2b52f0aaf",
                "sha256:c83faac49cbc38f1e458dfffb71b1c87860f56ac34602befefe6005177474ba3"
            ]
        },
        "Metadata": {
            "LastTagTime": "0001-01-01T00:00:00Z"
        }
    }
]
```

```text
> docker history python:3.6.4
IMAGE               CREATED             CREATED BY                                      SIZE                COMMENT
07d72c0beb99        8 months ago        /bin/sh -c #(nop)  CMD ["python3"]              0B
<missing>           8 months ago        /bin/sh -c set -ex;   wget -O get-pip.py 'ht…   6.06MB
<missing>           8 months ago        /bin/sh -c #(nop)  ENV PYTHON_PIP_VERSION=9.…   0B
<missing>           8 months ago        /bin/sh -c cd /usr/local/bin  && ln -s idle3…   32B
<missing>           8 months ago        /bin/sh -c set -ex  && buildDeps='   dpkg-de…   62.9MB
<missing>           8 months ago        /bin/sh -c #(nop)  ENV PYTHON_VERSION=3.6.4     0B
<missing>           8 months ago        /bin/sh -c #(nop)  ENV GPG_KEY=0D96DF4D4110E…   0B
<missing>           8 months ago        /bin/sh -c apt-get update && apt-get install…   8.67MB
<missing>           8 months ago        /bin/sh -c #(nop)  ENV LANG=C.UTF-8             0B
<missing>           8 months ago        /bin/sh -c #(nop)  ENV PATH=/usr/local/bin:/…   0B
<missing>           8 months ago        /bin/sh -c set -ex;  apt-get update;  apt-ge…   320MB
<missing>           8 months ago        /bin/sh -c apt-get update && apt-get install…   123MB
<missing>           8 months ago        /bin/sh -c set -ex;  if ! command -v gpg > /…   0B
<missing>           8 months ago        /bin/sh -c apt-get update && apt-get install…   44.6MB
<missing>           8 months ago        /bin/sh -c #(nop)  CMD ["bash"]                 0B
<missing>           8 months ago        /bin/sh -c #(nop) ADD file:bc844c4763367b5f0…   123MB
```

一个用来分析 docker 镜像层信息的一个工具：dive

该工具主要用于探索 docker 镜像层内容以及发现减小 docker 镜像大小的方法

## 项目地址

- Github 地址：<https://github.com/wagoodman/dive>

## 安装

直接使用 docker 镜像的方式，其他的安装方法在 dive 文档中查看即可

```bash
docker run --rm -it \
    -v /var/run/docker.sock:/var/run/docker.sock \
    wagoodman/dive:latest <dive arguments...>
# -e CI=true
```

## 使用

要分析一个 docker 镜像，只需要在 dive 工具后面添加上镜像的 tag 即可

```bash
dive <镜像TAG>
```

还可以通过 build 命令去构建 docker 镜像后，直接进入分析结果：

```bash
dive build -t <镜像TAG> .
```

如果想在 CI 中使用，则

```bash
CI=true dive <镜像TAG>
```

<img src=".assets/image-20221217135417571.png" alt="image-20221217135417571" style="zoom: 50%;" />

dive 提供功能如下：

- 显示镜像每层的内容

dive 的命令行界面分成左右两边，左边是镜像的层数，通过选择不同的镜像层，可以在右边显示对应的目录树结构

此外，可以使用箭头按键来浏览整个文件树内容

- 显示镜像每层的变更

通过选择对应的某一层，右边会根据不同的颜色标注该层文件的变化、修改、增加或者删除

- 估算镜像的空间利用率

通过分析每层出现的重复文件数、跨不同层移动文件、没有完全删除的文件等，可分析出来镜像中存在的额外不必要的空间占比，通过这个占比可以不断去推动缩小镜像的大小

镜像大小的减少可以带来很直接的好处，比如镜像拉去快服务启动也快

- 快速构建和分析的反馈环

可以构建 docker 镜像并使用一个命令立即进行分析：`dive build -t some-tag .`，只需要将 docker build 命令用相同的 dive build 命令替换即可

根据分析结果可快速作出是否需要优化的决策

- 集成 CI

通过在 dive build 前面添加 `CI=true` 就可以集成到对应的流水线流程中，通过设置不同的空间利用率来控制镜像构建是否通过

- 多种镜像源和容器引擎的支持

通过参数 `--source` 可以选择不同的镜像数据的格式源及不同容器的引擎

## 快捷键

| 快捷键       | 描述                                  |
| ------------ | ----------------------------------- |
| Ctrl + C     | 推出                                 |
| Tab          | 在图层和文件树视图之间切换               |
| Ctrl + F     | 过滤文件                              |
| PageUp       | 向上翻页                              |
| PageDown     | 向下翻页                              |
| Ctrl + A     | 图层视图：查看聚合图像修改               |
| Ctrl + L     | 图层视图：查看当前图层修改               |
| Space        | Filetree 视图：折叠/取消折叠目录         |
| Ctrl + Space | Filetree 视图：折叠/取消折叠全部目录      |
| Ctrl + A     | Filetree 视图： 显示/隐藏添加的文件      |
| Ctrl + R     | Filetree 视图：显示/隐藏已删除的文件     |
| Ctrl + M     | Filetree 视图：显示/隐藏已修改的文件     |
| Ctrl + U     | Filetree 视图：显示/隐藏未修改的文件     |
| Ctrl + B     | Filetree 视图：显示/隐藏文件属性         |
| PageUp       | Filetree 视图：向上滚动页面             |
| PageDown     | Filetree 视图：向下滚动页面            |
