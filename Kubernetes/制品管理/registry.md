## 搭建 registry 仓库

```bash
docker run \
	-itd \
	-p 5000:5000 \
	--restart=always \
	--name registry \
	registry:latest
```

curl 对应的端口，结果如下

````
curl http://127.0.0.1:5000/v2/_catalog
````

## 前端

可选的项目列表如下：

- https://github.com/kwk/docker-registry-frontend

容器列表：https://hub.docker.com/r/konradkleine/docker-registry-frontend/

```bash
docker run \
  -d \
  -e ENV_DOCKER_REGISTRY_HOST=ENTER-YOUR-REGISTRY-HOST-HERE \
  -e ENV_DOCKER_REGISTRY_PORT=ENTER-PORT-TO-YOUR-REGISTRY-HOST-HERE \
  -p 8080:80 \
  konradkleine/docker-registry-frontend:v2
```

- https://github.com/mkuchin/docker-registry-web

参考文档地址：https://juejin.cn/post/6956801823038504996