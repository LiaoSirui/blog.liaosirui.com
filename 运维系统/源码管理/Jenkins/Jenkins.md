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
    image: harbor.centuryfrontier.co/library/docker.io/jenkins/jenkins:2.567
    ports:
      - "8080:8080"
      - "50000:50000"
    environment:
      - TZ=Asia/Shanghai
      - JENKINS_UC=https://mirrors.cloud.tencent.com/jenkins/
      - JENKINS_UC_DOWNLOAD=https://mirrors.cloud.tencent.com/jenkins/
    volumes:
      - /var/jenkins_home:/var/jenkins_home
      - /var/run/docker.sock:/var/run/docker.sock
    user: root
    <<: *extras

```

## 参考资料

- <https://flyeric.top/archives/jenkins-ci-base-on-kubernetes>

- Gitlab 集成配置 <https://www.cnblogs.com/wgwyanfs/p/19641954>