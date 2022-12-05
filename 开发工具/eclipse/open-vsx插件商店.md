## 可选方案

## Open VSX

### 简介

官方地址：<https://open-vsx.org/>

GitHub 地址：<https://github.com/eclipse/openvsx>

### 运行和使用

当前最新的构建：<https://github.com/eclipse/openvsx/pkgs/container/openvsx-server/55672734?tag=v0.6.0>

使用 docker 启动一个测试

```bash
docker pull ghcr.io/eclipse/openvsx-server:v0.6.0

docker pull ghcr.io/eclipse/openvsx-webui:v0.6.0
```

同步到内部仓库

```bash
dockerhub.bigquant.ai:5000/aipaas-devops/3rdparty/ghcr.io/eclipse/openvsx-server:v0.6.0

dockerhub.bigquant.ai:5000/aipaas-devops/3rdparty/ghcr.io/eclipse/openvsx-webui:v0.6.0
```

<img title="" src="https://raw.githubusercontent.com/wiki/eclipse/openvsx/images/openvsx-architecture.png" alt="" width="551">

### 参考文档

[Eclipse Open VSX: A Free Marketplace for VS Code Extensions | The Eclipse Foundation](https://www.eclipse.org/community/eclipse_newsletter/2020/march/1.php)
