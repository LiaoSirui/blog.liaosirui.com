
拉取镜像

```bash
docker pull haishanh/yacd:v0.3.8

docker pull dreamacro/clash-premium:2022.08.26
```

下载配置文件

```bash
mkdir -p /registry/clash && cd /registry/clash

wget 'https://suburl.mimemi.net/link/cob6L6ETCpJcTlWn?dns=1&clashr=1' -O config.yaml
```

编写 docker-compose 编排文件

```yaml
version: '3'
services:
  clash:
    image: dreamacro/clash-premium:2022.08.26
    container_name: clash
    volumes:
      - /registry/clash/config.yaml:/root/.config/clash/config.yaml
      - /registry/clash/clash-ui:/root/.config/clash/clash-ui # dashboard volume
    ports:
      # rest api
      - "6170:6170"
      # proxy listening port
      - "8888:8888"
      - "8889:8889"
      - "8899:8899"
    restart: always
    network_mode: "bridge" # or "host" on Linux
    privileged: true

  clash-ui:
    image: haishanh/yacd:v0.3.8
    ports:
      - "17890:80"
    restart: always
    privileged: true
```

安装 docker-compose 的方式：

```bash
DOCKER_CONFIG=${DOCKER_CONFIG:-$HOME/.docker}
mkdir -p $DOCKER_CONFIG/cli-plugins
curl -SL https://github.com/docker/compose/releases/download/v2.12.2/docker-compose-linux-x86_64 -o $DOCKER_CONFIG/cli-plugins/docker-compose
chmod +x $DOCKER_CONFIG/cli-plugins/docker-compose
```

监听如下：

```bash
clash             | time="2022-04-04T08:08:52Z" level=info msg="HTTP proxy listening at: [::]:8888"
clash             | time="2022-04-04T08:08:52Z" level=info msg="SOCKS proxy listening at: [::]:8889"
clash             | time="2022-04-04T08:08:52Z" level=info msg="Mixed(http+socks) proxy listening at: [::]:8899"
```

再编辑 config.yaml 加入 external-ui: 目录名，使可以引入 clash dashboard

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

