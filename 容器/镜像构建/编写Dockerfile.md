
## 常用指令

### FROM 指令

FROM 主要是指定这个 Dockerfile 基于哪一个 base image 构建。Docker Dockerfile 按顺序运行指令。

```dockerfile
# 使用指定版本的 base image
FROM ubuntu:14.04
```

### LABEL 指令

LABEL 就像是代码中的注释。

可以包含镜像的作者、版本和描述信息。在开发中可以用来包含 commit id 等信息。

```dockerfile
LABEL maintainer="xxx@xxxx.com"
LABEL version="1.0"
LABEL description="This is description"
```

### RUN 指令

RUN 用来运行命令，其中命令必须是在第一行 FROM 中指定的 base image 所能运行的。

每运行一次 RUN，构建的 image 都会生成新的一层 layer。

```dockerfile
# 反斜杠换行
RUN yum update && yum install -y vim \
    python-dev
```

为了美观，复杂的RUN可以使用反斜杠换行。

为了避免无用分层，多条命令尽量合并一行。

### WORKDIR 指令

WORKDIR 用来设定当前工作目录。

```dockerfile
# 如果没有该目录，则会自动创建
WORKDIR /test
```

### ADD 和 COPY

ADD 和 COPY 作用相似，都是把本地的文件添加到 docker image 中。

区别：ADD 不仅可以添加文件，还可以解压缩文件，COPY 不可以解压缩文件。

```dockerfile
# 添加到 image 的根目录并且解压
ADD test.tar.gz /

COPY hello test/
```

大部分情况下 COPY 优于 ADD。

### ENV 指令

ENV 来设置环境变量或者一些常量

```dockerfile
# 设置常量
ENV MYSQL_VERSION 5.6

# 引用常量
RUN apt-get install -y mysql-server="${MYSQL_VERSION}" \
    && rm -rf /var/lib/apt/lists/*
```

### EXPOSE 指令

EXPOSE 设置容器暴露的端口，可以指定一个或多个端口

```dockerfile

```

<https://www.cnblogs.com/jie-fang/p/10279690.html>

<https://www.likecs.com/show-305974031.html#sc=2076>
