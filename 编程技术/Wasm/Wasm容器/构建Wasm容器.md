## 构建一个 Wasm 容器

一个非常简单的基于 scratch 的 Dockerfile 来制作一个可以使用 Docker+Wasm 运行的 OCI 镜像

需要先构建 Wasm 二进制文件，需要做的就是复制 Wasm 二进制文件并将其设置为 `ENTRYPOINT`

```dockerfile
FROM scratch

ADD ./build/main.wasm /build/main.wasm

ENTRYPOINT ["/build/main.wasm"]

```

## 对比

Wasm 二进制文件在本地和 Docker 容器中分别进行比较

以 PHP 为例

![img](.assets/%E6%9E%84%E5%BB%BAWasm%E5%AE%B9%E5%99%A8/up-2d9cde65bb1ec2d54ded3ea415fc078f3d2.jpg)