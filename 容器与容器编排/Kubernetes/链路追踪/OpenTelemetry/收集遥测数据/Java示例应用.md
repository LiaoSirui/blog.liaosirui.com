将使用一个名为 Petclinic 的 Java 应用程序，这是一个使用 Maven 或 Gradle 构建的 Spring Boot 应用程序。该应用程序将使用 OpenTelemetry 生成数据。

对于 Java 应用，我们可以通过下载 OpenTelemetry 提供的 opentelemetry-javaagent 这个 jar 包来使用 OpenTelemetry 自动检测应用程序。

只需要将这个 jar 包添加到应用程序的启动命令中即可，比如：

```bash
java -javaagent:opentelemetry-javaagent.jar -jar target/*.jar
```

Java 自动检测使用可附加到任何 Java 8+ 应用程序的 Java 代理 JAR。它动态注入字节码以从许多流行的库和框架捕获遥测数据。它可用于捕获应用程序或服务“边缘”的遥测数据，例如入站请求、出站 HTTP 调用、数据库调用等。通过运行以上命令，我们可以对应用程序进行插桩，并生成链路数据，而对我们的应用程序没有任何修改。

尤其是在 Kubernetes 环境中，可以使用 OpenTelemetry Operator 来注入和配置 OpenTelemetry 自动检测库，这样连 javaagent 我们都不需要去手动注入了。

首先部署 Petclinic 应用程序

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: petclinic
spec:
  selector:
    matchLabels:
      app: petclinic
  template:
    metadata:
      labels:
        app: petclinic
      annotations:
        instrumentation.opentelemetry.io/inject-java: "tracing/java-instrumentation"
        sidecar.opentelemetry.io/inject: "sidecar"
    spec:
      containers:
        - name: app
          image: cnych/spring-petclinic:latest
```

为了启用自动检测，我们需要更新部署文件并向其添加注解。这样我们可以告诉 OpenTelemetry Operator 将 sidecar 和 java-instrumentation 注入到我们的应用程序中。

再创建一个 NodePort 类型的 Service 服务来暴露应用程序

```yaml
apiVersion: v1
kind: Service
metadata:
  name: petclinic
spec:
  selector:
    app: petclinic
  type: NodePort
  ports:
    - protocol: TCP
      port: 80
      targetPort: 8080
```

正常部署完成后可以看到对应的 Pod 已经正常运行

就可以通过 `http://<node_ip>:30941` 来访问 Petclinic 应用程序

当我们访问应用程序时，应用程序就将生成追踪数据，并将其发送到我们的中心收集器。同时也可以在在 Jaeger 中看到对应的追踪数据。