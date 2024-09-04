拉取镜像

```bash
docker pull haishanh/yacd:v0.3.8

docker pull dreamacro/clash-premium:2023.04.16
```

下载配置文件

```bash
mkcd ./clash

wget 'https://suburl.mimemi.net/link/cob6L6ETCpJcTlWn?dns=1&clashr=1' -O config.yaml
```

config.yaml 加入 external-ui: 目录名，使可以引入 clash dashboard

```yaml
1 ---
2 port: 8888
3 socks-port: 8889
4 mixed-port: 8899
5 allow-lan: true
6 external-ui: clash-ui
7 mode: Rule
8 log-level: info
9 external-controller: 0.0.0.0:6170
```

更改配置文件

```bash
yq -i '.external-controller = "0.0.0.0:6170"' config.yaml
yq -i '.external-ui = "clash-ui"' config.yaml
yq -i '.log-level = "error"' config.yaml
yq -i 'with(.proxy-groups[]; . | select(.name == "Auto") | .interval = "3600")' config.yaml
```

编写 docker-compose 编排文件

```yaml
version: '3'
services:
    image: dreamacro/clash-premium:2022.08.26
```

```yaml
version: '3'
services:
  clash:
    image: dreamacro/clash-premium:~
    container_name: clash
    volumes:
      - ./config.yaml:/root/.config/clash/config.yaml
      # dashboard volume
      - ./clash-ui:/root/.config/clash/clash-ui
    # ports:
    #   # rest api
    #   - "6170:6170"
    #   # proxy listening port
    #   - "8888:8888"
    #   - "8889:8889"
    #   - "8899:8899"
    restart: always
    # "bridge" or "host"
    network_mode: "host"
    privileged: true

  clash-ui:
    image: haishanh/yacd:v0.3.8
    ports:
      - "17890:80"
    restart: always
    entrypoint: /bin/sh -c "/bin/sh -c \"$${@}\""
    command: |
      /bin/sh -c "
        sed -i 's|127.0.0.1:9090|10.244.2444.3:6170|' /usr/share/nginx/html/index.html
        sed -i 's|worker_processes |worker_processes 4;#|' /etc/nginx/nginx.conf
        nginx -g 'daemon off;'
      "
```

安装 docker-compose 的方式：

```bash
export DOCKER_CONFIG=${DOCKER_CONFIG:-$HOME/.docker}

mkdir -p $DOCKER_CONFIG/cli-plugins

curl -L https://github.com/docker/compose/releases/download/v2.15.1/docker-compose-linux-x86_64 \
  -o $DOCKER_CONFIG/cli-plugins/docker-compose

chmod +x $DOCKER_CONFIG/cli-plugins/docker-compose
```

监听如下：

```bash
clash             | time="2022-04-04T08:08:52Z" level=info msg="HTTP proxy listening at: [::]:8888"
clash             | time="2022-04-04T08:08:52Z" level=info msg="SOCKS proxy listening at: [::]:8889"
clash             | time="2022-04-04T08:08:52Z" level=info msg="Mixed(http+socks) proxy listening at: [::]:8899"
```

## 更新配置文件脚本

```bash
#!/usr/bin/env bash

suffix=$(date +"%Y%m%d-%H%M%S")
backup_dir="backup_config"

export yq="/var/app/clash/bin/yq_linux_amd64"

cd /var/app/clash || exit 1

# backup config
mkdir -p ${backup_dir}
cp config.yaml "${backup_dir}/config.yaml.${suffix}"

wget -O config-new.yaml 'https://suburl.mimemi.net/link/PQUNsArhzbxz9xck?dns=1&clash=1'

"$yq" -i '.external-controller = "0.0.0.0:6170"' config-new.yaml
"$yq" -i '.external-ui = "clash-ui"' config-new.yaml
"$yq" -i '.log-level = "error"' config-new.yaml
"$yq" -i 'with(.proxy-groups[]; . | select(.name == "Auto") | .interval = "120")' config-new.yaml

mv config-new.yaml config.yaml

# diff config-new.yaml config.yaml > /dev/null || (mv -f config-new.yaml config.yaml && docker-compose restart)
# docker-compose up -d
docker compose down
docker compose up -d
```
