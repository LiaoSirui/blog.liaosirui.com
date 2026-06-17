MetaCubeX

- MacOS 端：<https://github.com/MetaCubeX/ClashX.Meta>
- Linux：<https://github.com/MetaCubeX/metacubexd>

安装

``` bash
dnf install -y https://github.com/MetaCubeX/mihomo/releases/download/v1.19.27/mihomo-linux-amd64-v3-v1.19.27.rpm
```

docker compose 运行

```yaml
x-extras: &extras
  restart: unless-stopped
  networks:
    - public
  logging:
    driver: "json-file"
    options:
      max-size: "1m"
      max-file: "1"

networks:
  public:
    name: public
    external: true

services:
  mihomo:
    image: ${INST_MIHOMO_IMAGE}
    container_name: metacubex-mihomo
    privileged: true
    volumes:
      - ./config.yaml:/etc/mihomo/config.yaml
      - ${INST_CLASH_DIR}/config.d:/etc/mihomo/config.d
    ports:
      - "8899:8899"
      - "8899:8899/udp"
      - "6170:6170"
    deploy:
      resources:
        limits:
          cpus: "1.00"
          memory: 2G
    <<: *extras

  metacubexd:
    image: ${INST_METACUBEXD_IMAGE}
    container_name: metacubex-metacubexd
    ports:
      - "18899:80"
    deploy:
      resources:
        limits:
          cpus: "1.00"
          memory: 2G
    <<: *extras

```

配置文件 `/etc/mihomo/config.yaml`

```yaml
mixed-port: 8899
bind-address: '*'
allow-lan: true
external-controller: "0.0.0.0:6170"
mode: rule
secret: "proxy.alpha-quant.tech"
proxies: []
proxy-groups: []
my-url-test: &my-url-test
  health-check:
    enable: true
    url: https://www.gstatic.com/generate_204
    interval: 300
    timeout: 1000
    tolerance: 100
proxy-providers:
  "rabbitpro":
    type: http
    url: "https://remote"
    path: /root/.config/mihomo/config.d/remote.yaml
    interval: 3600
    <<: *my-url-test
dns:
  enable: true
  ipv6: true
  nameserver:
    - 223.5.5.5
    - 8.8.8.8
    - 8.8.4.4
# authentication:
#   - "user:password"
rules:
  - 'IP-CIDR,127.0.0.0/32,DIRECT'
  - 'DOMAIN-SUFFIX,local,DIRECT'
  - 'DOMAIN-SUFFIX,localhost,DIRECT'
  - 'IP-CIDR,10.0.0.0/8,DIRECT'
  - 'IP-CIDR,172.16.0.0/12,DIRECT'
  - 'IP-CIDR,192.168.0.0/16,DIRECT'
  - 'DOMAIN-SUFFIX,alpha-quant.com.cn,DIRECT'
  - 'DOMAIN-SUFFIX,alpha-quant.cn,DIRECT'
  - 'DOMAIN-SUFFIX,alpha-quant.tech,DIRECT'
  - MATCH,rabbitpro
```

