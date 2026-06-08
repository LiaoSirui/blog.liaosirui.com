## 快速入门

测试

```yaml
networks:
  public:
    name: public
    external: true
    ipam:
      driver: default

x-extras: &extras
  restart: unless-stopped
  networks:
    - public
  logging:
    driver: "json-file"
    options:
      max-size: "1m"
      max-file: "1"

services:
  jenkins:
    image: harbor.alpha-quant.tech/library/docker.io/jenkins/jenkins:2.567
    ports:
      - "8080:8080"
      - "50000:50000"
    environment:
      - TZ=Asia/Shanghai
      # 代理加速插件下载
      - https_proxy=http://192.168.3.179:7897
      - http_proxy=http://192.168.3.179:7897
      - all_proxy=socks5://192.168.3.179:7897
      - NO_PROXY=127.0.0.1,10.0.0.0/8,172.16.0.0/12,192.168.0.0/16,localhost,.local,.k8s.cfi,.centuryfrontier.co
      - HTTPS_PROXY=http://192.168.3.179:7897
      - HTTP_PROXY=http://192.168.3.179:7897
      - ALL_PROXY=socks5://192.168.3.179:7897
      # 代理配置
    volumes:
      - /var/jenkins_home:/var/jenkins_home
      - /var/run/docker.sock:/var/run/docker.sock
    user: root
    <<: *extras

```

## 参考资料

- <https://flyeric.top/archives/jenkins-ci-base-on-kubernetes>

- Gitlab 集成配置 <https://www.cnblogs.com/wgwyanfs/p/19641954>