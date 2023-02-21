

多阶段构建优势

针对 Java 这类的编译型语言，使用 Dockerfile 多阶段构建，具有以下优势：

- 保证构建镜像的安全性：当使用 Dockerfile 多阶段构建镜像时，需要在第一阶段选择合适的编译时基础镜像，进行代码拷贝、项目依赖下载、编译、测试、打包流程。在第二阶段选择合适的运行时基础镜像，拷贝基础阶段生成的运行时依赖文件。最终构建的镜像将不包含任何源代码信息。

- 优化镜像的层数和体积：构建的镜像仅包含基础镜像和编译制品，镜像层数少，镜像文件体积小。

- 提升构建速度：使用构建工具（Docker、Buildkit 等），可以并发执行多个构建流程，缩短构建耗时。

官方：

- Maven 官方镜像：<https://hub.docker.com/_/maven>
- OpenJDK 官方镜像：<https://hub.docker.com/_/openjdk>


## Maven 项目示例

Maven 是目前最流行的 Java 项目管理工具之一，提供了强大的包依赖管理和应用构建功能。

使用 Maven 先创建一个 SpringBoot 的项目

```bash
mvn archetype:generate \
  -DarchetypeCatalog=internal \
  -DinteractiveMode=false \
  -DremoteRepositories=http://maven.aliyun.com/nexus/content/groups/public \
  -DarchetypeArtifactId=maven-archetype-webapp \
  -DgroupId=com.liaosirui.demo \
  -DartifactId=maven-demo \
  -Dpackage=com.liaosirui.demo \
  -Dversion=1.0-SNAPSHOT

```

给项目添加一个声明使用内部仓库或者其他 Maven 代理仓库

```xml
<project xmlns="http://maven.apache.org/POM/4.0.0"
  xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
  xsi:schemaLocation="http://maven.apache.org/POM/4.0.0 http://maven.apache.org/maven-v4_0_0.xsd">
  ...
  <dependencies>
    <dependency>
      <groupId>junit</groupId>
      <artifactId>junit</artifactId>
      <version>3.8.1</version>
      <scope>test</scope>
    </dependency>
  </dependencies>
  <!-- repositories and pluginRepositories here-->
  <repositories>
    <repository>
      <id>nexus-aliyun</id>
      <name>Nexus aliyun</name>
      <url>http://maven.aliyun.com/nexus/content/groups/public</url>
      <releases>
        <enabled>true</enabled>
      </releases>
      <snapshots>
        <enabled>true</enabled>
      </snapshots>
    </repository>
  </repositories>
  <!-- end repositories and pluginRepositories here-->
  ...
</project>

```

以 Java Maven 项目为例，在 Java Maven 项目中新建 Dockerfile 文件，并在 Dockerfile  文件添加以下内容。

```dockerfile
# First stage: complete build environment
FROM maven:3.8.6-openjdk-8 AS builder

# add pom.xml and source code
# ADD settings.xml /etc/maven/settings.xml
ADD ./pom.xml pom.xml
ADD ./src src/

# package jar
RUN mvn clean package

# Second stage: minimal runtime environment
From openjdk:8-jre

# copy jar from the first stage
COPY --from=builder target/my-app-1.0-SNAPSHOT.jar my-app-1.0-SNAPSHOT.jar

EXPOSE 8080

CMD ["java", "-jar", "my-app-1.0-SNAPSHOT.jar"]
```

