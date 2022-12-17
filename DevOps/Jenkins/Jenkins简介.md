
## 适合的场景

Jenkinsfile 的实践场景：

进行持续集成和部署，最终的实现很有可能是 Jenkins上 的一个 Job，有可能是 FreeStyle 的和有可能是其他形式的，通过插件或其他方式我们打通了 Jenkins 和其他组件，可以使得用户在 Jenkins 上通过使用 Gitlab 拉取分支代码，使用 Maven 进行构建，将结果上传至二进制私库 Nexus 上，使用 SonarQube 进行代码扫描，通过 Docker 进行镜像生成，将镜像推送至 Harbor 镜像私库上，使用 Ansible 进行服务部署等常见操作

而这些操作大部分都是共通的，而不同的大多是这些组件工具的 URL 和用户名/密码或者 Token 有所不同，而 Jenkins 的打通过程，传统方式往往以手工方式为主，持续集成和持续交付本身是为了带来效率的，这个打通的过程自身一旦稳定往往并不像应用程序变更那样频繁，但是作为软件开发生命周期不可获取的一个环节，这些流水线手工设定的过程也应该以代码的形式保存起来，这样才能保证持续集成环境的一致性和可扩展性。而 Jenkinsfile 就是将持续集成和持续交付流水线以代码形式进行保存的一种方式。

## 启动 jenkins

使用 Easypack 中准备好的 LTS 的 Jenkins 镜像，启动 Jenkins

```bash
git clone https://github.com/liumiaocn/easypack.git
```

启动服务

```bash
cd easypack/containers/alpine/jenkins
```

直接使用给的 docker-compose.yml 快速拉起环境

```yaml
version: '2'

services:
  # jenkins service based on Jenkins LTS version
  jenkins:
    image: liumiaocn/jenkins:2.176.1
    ports:
      - "32002:8080"
      - "50000:50000"
    environment:
      - JENKINS_ADMIN_ID=root
      - JENKINS_ADMIN_PW=password
      - JENKINS_MODE=master
      - JAVA_OPTS=-Djenkins.install.runSetupWizard=false
    volumes:
      - ./data/:/data/jenkins
      - /var/run/docker.sock:/var/run/docker.sock
    restart: "no"

```
