## 简介

`Draw.io` 是一款开源的绘制流程图的工具，拥有大量免费素材和模板。程序本身支持中文在内的多国语言，创建的文档可以导出到多种网盘或本地。无论是创建流程图、组织结构图、网络拓扑图还是其他类型的图表。

本地部署 Draw.io 并结合 GitLab 等代码/文档管理平台

```bash
docker run -it -m1g -e LETS_ENCRYPT_ENABLED=false -e PUBLIC_DNS=drawio.example.com --rm --name="draw" -p 8080:8080 -p 8443:8443 jgraph/drawio
```

启动后访问链接：<http://localhost:8080/?offline=1&https=0⁠>

镜像：<https://hub.docker.com/r/jgraph/drawio/tags>

当前最新镜像

```bash
docker pull jgraph/drawio:28.0.7
```

## 参考资料

- <https://www.drawio.com/blog/diagrams-docker-app>