Kaniko 是 Google 开源的一款容器镜像构建工具，可以在容器或 Kubernetes 集群内从 Dockerfile 构建容器镜像，`Kaniko` 构建容器镜像时并不依赖于 docker daemon，也不需要特权模式，而是完全在用户空间中执行 Dockerfile 中的每条命令，这使得在无法轻松或安全地运行 docker daemon 的环境下构建容器镜像成为了可能。

![image-20230220112700051](.assets/image-20230220112700051.png)

Kaniko 构建容器镜像时，需要使用 Dockerfile、构建上下文、以及构建成功后镜像在仓库中的存放地址。此外 Kaniko 支持多种方式将构建上下文挂载到容器中，比如可以使用本地文件夹、GCS bucket、S3 bucket 等方式，使用 GCS 或者 S3 时需要把上下文压缩为 `tar.gz`，kaniko 会自行在构建时解压上下文。

`Kaniko executor` 读取 Dockerfile 后会逐条解析 Dockerfile 内容，一条条执行命令，每一条命令执行完以后会在用户空间下面创建一个 snapshot，并与存储与内存中的上一个状态进行比对，如果有变化，就将新的修改生成一个镜像层添加在基础镜像上，并且将相关的修改信息写入镜像元数据中，等所有命令执行完，kaniko 会将最终镜像推送到指定的远端镜像仓库。。整个过程中，完全不依赖于 docker daemon。

如下所示我们有一个简单的 Dokerfile 示例：

```
FROM alpine:latest
RUN apk add busybox-extras curl
CMD ["echo","Hello Kaniko"]
```

然后我们可以启动一个 kaniko 容器去完成上面的镜像构建，当然也可以直接在 Kubernetes 集群中去运行，如下所示新建一个 kaniko 的 Pod 来构建上面的镜像：

```
apiVersion: v1
kind: Pod
metadata:
  name: kaniko
spec:
  containers:
  - name: kaniko
    image: gcr.io/kaniko-project/executor:latest
    args: ["--dockerfile=/workspace/Dockerfile",
          "--context=/workspace/",
          "--destination=cnych/kaniko-test:v0.0.1"]
    volumeMounts:
      - name: kaniko-secret
        mountPath: /kaniko/.docker
      - name: dockerfile
        mountPath: /workspace/Dockerfile
        subPath: Dockerfile
  volumes:
    - name: dockerfile
      configMap:
        name: dockerfile
    - name: kaniko-secret
        projected:
         sources:
         - secret:
            name: regcred
            items:
            - key: .dockerconfigjson
              path: config.json
```

上面的 Pod 执行的 args 参数中，主要就是指定 kaniko 运行时需要的三个参数: `Dockerfile`、构建上下文以及远端镜像仓库。

推送至指定远端镜像仓库需要 credential 的支持，所以需要将 credential 以 secret 的方式挂载到 `/kaniko/.docker/` 这个目录下，文件名称为 `config.json`，内容如下:

```
{
    "auths": {
        "https://index.docker.io/v1/": {
            "auth": "AbcdEdfgEdggds="
       }
    }

}
```

其中 auth 的值为: `docker_registry_username:docker_registry_password`base64 编码过后的值。然后 Dockerfile 通过 Configmap 的形式挂载进去，如果构建上下文中还有其他内容也需要一同挂载进去。

关于 kaniko 的更多使用方式可以参考官方仓库：https://github.com/GoogleContainerTools/kaniko。