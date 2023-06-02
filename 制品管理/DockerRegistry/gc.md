先清理 tag

```bash
lias registry-cli='docker run --rm --add-host local.repo:192.168.146.1 docker.io/anoxis/registry-cli:latest'

registry-cli -r http://local.repo:5000 -i <proj>/<image> --delete --num 10
```

执行如下 gc

```bash
docker rm -f docker-registry

docker rm -f docker-registry-gc

docker run -d --restart=always \
    -p 5000:5000 \
    --name docker-registry-gc \
    -v `pwd`/data:/var/lib/registry \
    -e REGISTRY_STORAGE_DELETE_ENABLED=true \
    --entrypoint=/bin/registry \
    registry:2.7.1 \
    garbage-collect --delete-untagged /etc/docker/registry/config.yml

docker rm -f docker-registry-gc

docker run -d --restart=always \
    -p 5000:5000 \
    --name docker-registry \
    -v `pwd`/data:/var/lib/registry \
    -e REGISTRY_STORAGE_DELETE_ENABLED=true \
    registry:2.7.1

```

