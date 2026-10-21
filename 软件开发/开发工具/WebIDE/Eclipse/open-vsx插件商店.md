## 可选方案

## Open VSX

### 简介

官方地址：<https://open-vsx.org/>

GitHub 地址：<https://github.com/eclipse/openvsx>

### 运行和使用

当前最新的构建：<https://github.com/eclipse/openvsx/pkgs/container/openvsx-server/55672734?tag=v0.6.0>

使用 docker 启动一个测试

```bash
docker pull ghcr.io/eclipse/openvsx-server:v0.6.0

docker pull ghcr.io/eclipse/openvsx-webui:v0.6.0
```

同步到内部仓库

```bash
ghcr.io/eclipse/openvsx-server:v0.6.0

ghcr.io/eclipse/openvsx-webui:v0.6.0
```

- 主体为OpenVSX-Server，spring boot框架的java服务，我们在部署时需要自行添加 application.yml 配置文件，并将其放置对应位置，以便Server启动后加载。
- 后台数据库使用PostgreSql，并使用Pgadmin进行数据库的管理和查询等操作，数据库的创建和表结构的初始化过程Server进程启动时会自动执行。
- 前端界面为NodeJS架构的Web UI，我们在部署时会将前端代码库构建的静态网站结果放入Server服务的对应文件夹，使其二者变为一个进程即Server进程加入前端界面。这也是Sprint Boot框架的灵活性功能，使用者可以基于Web UI代码库自定制前端界面，并将自定制的前端页面嵌入Server服务。
- 用户登陆验证，目前只支持OAuth Provider，官方文档中声明目前只支持Github AuthApp和 Eclipse OAuth，我们在部署时使用Github AuthApp。
- 插件存储可以使用数据库（默认）、Google Storage或 Azure Blob Storage三种模式，推荐添加Google Storage或 Azure Blob Storage以避免数据库过大的情况出现。
- 插件搜索服务支持数据库搜索和附加Elastic Search服务两种模式，推荐有条件的情况下添加Elastic Search搜索服务提高搜索效率，降低数据库压力。
- 除以上架构图中展现内容外，Marketplace网站需要配置HTTPS证书，这样才服务器的扩展才能够正确被IDE加载，我们使用Nginx进行服务器的部署端口转发。

更多仓库： https://github.com/eclipsefdn/open-vsx.org

## 部署

启动 server 需要一个 application.yml，需要放到 server 的 /home/openvsx/server/config 目录中，配置参考：https://github.com/eclipse/openvsx/blob/master/server/src/dev/resources/application.yml

文档地址：https://github.com/eclipse/openvsx/wiki/Deploying-Open-VSX#configuring-applicationyml

使用 k8s 部署：

```yaml
---
apiVersion: v1
kind: Namespace
metadata:
  name: open-vsx

```

db:

```yaml
---
apiVersion: v1
kind: ServiceAccount
metadata:
  name: open-vsx-db
  namespace: open-vsx
  labels:
    app.kubernetes.io/name: open-vsx-db
 
---
apiVersion: v1
kind: Service
metadata:
  name: open-vsx-db
  namespace: open-vsx
  labels:
    app.kubernetes.io/name: open-vsx-db
spec:
  type: ClusterIP
  ports:
    - port: 5432
      targetPort: postgres
      protocol: TCP
      name: postgres
  selector:
    app.kubernetes.io/name: open-vsx-db
 
---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: open-vsx-db
  namespace: open-vsx
  labels:
    app.kubernetes.io/name: open-vsx-db
spec:
  storageClassName: manual
  accessModes:
    - ReadWriteOnce
  selector:
    matchLabels:
      app.kubernetes.io/name: open-vsx-db
  resources:
    requests:
      storage: "10Gi"
 
---
apiVersion: v1
kind: PersistentVolume
metadata:
  name: open-vsx-db
  namespace: open-vsx
  labels:
    app.kubernetes.io/name: open-vsx-db
spec:
  storageClassName: manual
  capacity:
    storage: 10Gi
  accessModes:
    - ReadWriteOnce
  hostPath:
    path: "/data/open-vsx/open-vsx-db"
  nodeAffinity:
    required:
      nodeSelectorTerms:
        - matchExpressions:
            - key: kubernetes.io/hostname
              operator: In
              values:
                - monitoring-node01   
 
---
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: open-vsx-db
  namespace: open-vsx
  labels:
    app.kubernetes.io/name: open-vsx-db
spec:
  replicas: 1
  selector:
    matchLabels:
      app.kubernetes.io/name: open-vsx-db
  serviceName: open-vsx-db
  template:
    metadata:
      labels:
        app.kubernetes.io/name: open-vsx-db
    spec:
      nodeSelector:
        kubernetes.io/os: linux
      affinity:
        podAntiAffinity:
          preferredDuringSchedulingIgnoredDuringExecution:
          - weight: 1
            podAffinityTerm:
              labelSelector:
                matchLabels:
                  app.kubernetes.io/name: code-marketplace
              namespaces:
              - aipaas-system
              topologyKey: kubernetes.io/hostname
        nodeAffinity:
          requiredDuringSchedulingIgnoredDuringExecution:
            nodeSelectorTerms:
            - matchExpressions:
              - key: kubernetes.io/hostname
                operator: In
                values:
                - monitoring-node01
      tolerations:
      - effect: NoSchedule
        key: no-pod
        operator: Equal
        value: "true"
      - effect: NoSchedule
        key: aipaas-monitor
        operator: Exists
      - effect: NoExecute
        key: node.kubernetes.io/not-ready
        operator: Exists
        tolerationSeconds: 300
      - effect: NoExecute
        key: node.kubernetes.io/unreachable
        operator: Exists
        tolerationSeconds: 300
      imagePullSecrets:
      - name: aipaas-image-pull-secrets
      serviceAccountName: open-vsx-db
      volumes:
      - name: db
        persistentVolumeClaim:
          claimName: open-vsx-db
      containers:
      - name: postgres
        image: docker.io/library/postgres:13.9
        resources:
          requests:
            memory: "512Mi"
            cpu: "500m"
          limits:
            memory: "512Mi"
            cpu: "500m"
        ports:
        - name: postgres
          containerPort: 5432
          protocol: TCP
        env:
        - name: POSTGRES_USER
          value: open-vsx
        - name: POSTGRES_PASSWORD
          value: open-vsx
        - name: POSTGRES_DB
          value: open-vsx
        volumeMounts:
        - name: db
          mountPath: /var/lib/postgresql
```

es

部署 es 时要注意，宿主机目录需要授权为 1000:1000

```yaml
---
apiVersion: v1
kind: ServiceAccount
metadata:
  name: open-vsx-es
  namespace: open-vsx
  labels:
    app.kubernetes.io/name: open-vsx-es
 
---
apiVersion: v1
kind: Service
metadata:
  name: open-vsx-es
  namespace: open-vsx
  labels:
    app.kubernetes.io/name: open-vsx-es
spec:
  type: ClusterIP
  clusterIP: None
  ports:
    - name: rest
      protocol: TCP
      port: 9200
      targetPort: rest
    - name: inter-node
      protocol: TCP
      port: 9300
      targetPort: inter-node
  selector:
    app.kubernetes.io/name: open-vsx-es
 
---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: open-vsx-es
  namespace: open-vsx
  labels:
    app.kubernetes.io/name: open-vsx-es
spec:
  storageClassName: manual
  accessModes:
  - ReadWriteOnce
  selector:
    matchLabels:
      app.kubernetes.io/name: open-vsx-es
  resources:
    requests:
      storage: "10Gi"
---
apiVersion: v1
kind: PersistentVolume
metadata:
  name: open-vsx-es
  namespace: open-vsx
  labels:
    app.kubernetes.io/name: open-vsx-es
spec:
  storageClassName: manual
  capacity:
    storage: 10Gi
  accessModes:
  - ReadWriteOnce
  hostPath:
    path: "/data/open-vsx/open-vsx-es"
  nodeAffinity:
    required:
      nodeSelectorTerms:
      - matchExpressions:
        - key: kubernetes.io/hostname
          operator: In
          values:
```

open-vsx

创建 github oatuh app 的文档：https://docs.github.com/en/developers/apps/building-oauth-apps/creating-an-oauth-app

```yaml
---
apiVersion: v1
kind: ServiceAccount
metadata:
  name: open-vsx
  namespace: open-vsx
  labels:
    app.kubernetes.io/name: open-vsx
 
---
apiVersion: v1
kind: Service
metadata:
  name: open-vsx
  namespace: open-vsx
  labels:
    app.kubernetes.io/name: open-vsx
spec:
  type: ClusterIP
  ports:
    - port: 8080
      targetPort: open-vsx
      protocol: TCP
      name: open-vsx
  selector:
    app.kubernetes.io/name: open-vsx
 
---
apiVersion: v1
kind: ConfigMap
metadata:
  name: open-vsx-config
  namespace: open-vsx
  labels:
    app.kubernetes.io/name: open-vsx
data:
  application.yml: |-
    spring:
      datasource:
        url: jdbc:postgresql://open-vsx-db:5432/open-vsx
        username: open-vsx
        password: open-vsx
        # refer: https://stackoverflow.com/questions/60310858/possibly-consider-using-a-shorter-maxlifetime-value-hikari-connection-pool-spr
        # 10 minutes wait time
        hikari:
          maxLifeTime: 600000
      jpa:
        properties:
          hibernate:
            dialect: org.hibernate.dialect.PostgreSQLDialect
        hibernate:
          ddl-auto: none
      session:
        store-type: jdbc
        jdbc:
          initialize-schema: never
      security:
        oauth2:
          client:
            registration:
              github:
                clientId: c8568646a271787192d4
                clientSecret: 7929d4fb5c6b053880c68ae1d36d3e1aa286186f
    ovsx:
      elasticsearch:
        enabled: true
        host: open-vsx-es:9200
      databasesearch:
        enabled: false
      webui:
        url: https://openvsx.xxx.com
   
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: open-vsx
  namespace: open-vsx
  annotations:
    configmap.reloader.stakater.com/reload: "open-vsx-config"
  labels:
    app.kubernetes.io/name: open-vsx
spec:
  selector:
    matchLabels:
      app.kubernetes.io/name: open-vsx
  template:
    metadata:
      labels:
        app.kubernetes.io/name: open-vsx
    spec:
      nodeSelector:
        kubernetes.io/os: linux
      affinity:
        podAntiAffinity:
          preferredDuringSchedulingIgnoredDuringExecution:
          - weight: 1
            podAffinityTerm:
              labelSelector:
                matchLabels:
                  app.kubernetes.io/name: code-marketplace
              namespaces:
              - aipaas-system
              topologyKey: kubernetes.io/hostname
        nodeAffinity:
          requiredDuringSchedulingIgnoredDuringExecution:
            nodeSelectorTerms:
            - matchExpressions:
              - key: kubernetes.io/hostname
                operator: In
                values:
                - monitoring-node01
      tolerations:
      - effect: NoSchedule
        key: no-pod
        operator: Equal
        value: "true"
      - effect: NoSchedule
        key: aipaas-monitor
        operator: Exists
      - effect: NoExecute
        key: node.kubernetes.io/not-ready
        operator: Exists
        tolerationSeconds: 300
      - effect: NoExecute
        key: node.kubernetes.io/unreachable
        operator: Exists
        tolerationSeconds: 300
      imagePullSecrets:
      - name: aipaas-image-pull-secrets
      serviceAccountName: open-vsx
      containers:
      - name: open-vsx
        image: ghcr.io/eclipse/openvsx-server:v0.6.0
        resources:
          requests:
            memory: "512Mi"
            cpu: "500m"
          limits:
            memory: "512Mi"
            cpu: "500m"
        ports:
        - name: open-vsx
          containerPort: 8080
          protocol: TCP
        volumeMounts:
        - name: config
          mountPath: /home/openvsx/server/config/application.yml
          readOnly: true
      volumes:
      - name: config
        configMap:
          name: open-vsx-config
          items:
          - key: application.yml
            path: application.yml
```

创建 web-ui

```yaml
---
apiVersion: v1
kind: ServiceAccount
metadata:
  name: open-vsx-ui
  namespace: open-vsx
  labels:
    app.kubernetes.io/name: open-vsx-ui
 
---
apiVersion: v1
kind: Service
metadata:
  name: open-vsx-ui
  namespace: open-vsx
  labels:
    app.kubernetes.io/name: open-vsx-ui
spec:
  type: ClusterIP
  ports:
  - port: 3000
    targetPort: open-vsx-ui
    protocol: TCP
    name: open-vsx-ui
  selector:
    app.kubernetes.io/name: open-vsx-ui
 
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: open-vsx-ui
  namespace: open-vsx
  labels:
    app.kubernetes.io/name: open-vsx-ui
spec:
  selector:
    matchLabels:
      app.kubernetes.io/name: open-vsx-ui
  template:
    metadata:
      labels:
        app.kubernetes.io/name: open-vsx-ui
    spec:
      nodeSelector:
        kubernetes.io/os: linux
      affinity:
        podAntiAffinity:
          preferredDuringSchedulingIgnoredDuringExecution:
          - weight: 1
            podAffinityTerm:
              labelSelector:
                matchLabels:
                  app.kubernetes.io/name: code-marketplace
              namespaces:
              - aipaas-system
              topologyKey: kubernetes.io/hostname
        nodeAffinity:
          requiredDuringSchedulingIgnoredDuringExecution:
            nodeSelectorTerms:
            - matchExpressions:
              - key: kubernetes.io/hostname
                operator: In
                values:
                - monitoring-node01
                - monitoring-node02
                - monitoring-node03
      tolerations:
      - effect: NoSchedule
        key: no-pod
        operator: Equal
        value: "true"
      - effect: NoSchedule
        key: aipaas-monitor
        operator: Exists
      - effect: NoExecute
        key: node.kubernetes.io/not-ready
        operator: Exists
        tolerationSeconds: 300
      - effect: NoExecute
        key: node.kubernetes.io/unreachable
        operator: Exists
        tolerationSeconds: 300
      imagePullSecrets:
      - name: aipaas-image-pull-secrets
      serviceAccountName: open-vsx-ui
      containers:
      - name: open-vsx-ui
        image: ghcr.io/eclipse/openvsx-webui:v0.6.0
        resources:
          requests:
            memory: "512Mi"
            cpu: "500m"
          limits:
            memory: "512Mi"
            cpu: "500m"
        ports:
        - name: open-vsx-ui
          containerPort: 3000
          protocol: TCP
```

创建 ingress

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: open-vsx
  namespace: open-vsx
  labels:
    app.kubernetes.io/name: open-vsx
  annotations:
    cert-manager.io/cluster-issuer: letsencrypt
    kubernetes.io/ingress.class: nginx
    nginx.ingress.kubernetes.io/proxy-body-size: 1024m
    nginx.ingress.kubernetes.io/proxy-buffer-size: 256k
spec:
  tls:
  - hosts:
    - openvsx.xxx.com
    secretName: open-vsx-https-secret
  rules:
  - host: openvsx.xxx.com
    http:
      paths:
      - pathType: Prefix
        path: "/"
        backend:
          service:
            name: open-vsx-ui
            port:
              name: open-vsx-ui
      - pathType: Prefix
        path: "/user"
        backend:
          service:
            name: open-vsx
            port:
              name: open-vsx
      - pathType: Prefix
        path: "/api"
        backend:
          service:
            name: open-vsx
            port:
              name: open-vsx
      - pathType: Prefix
        path: "/admin"
        backend:
          service:
            name: open-vsx
            port:
              name: open-vsx
      - pathType: Prefix
        path: "/login"
        backend:
          service:
            name: open-vsx
            port:
              name: open-vsx
      - pathType: Prefix
        path: "/logout"
        backend:
          service:
            name: open-vsx
            port:
              name: open-vsx
      - pathType: Prefix
        path: "/oauth2"
        backend:
          service:
            name: open-vsx
            port:
              name: open-vsx
      - pathType: Prefix
        path: "/vscode"
        backend:
          service:
            name: open-vsx
            port:
              name: open-vsx
```

配置好 idp 后，由于网络原因，还需要给 server 配置代理才能获取到用户信息

环境变量注入代理

```yaml

           env:
            - name: http_proxy
              value: 'http://192.168.148.116:8899'
            - name: https_proxy
              value: 'socks5://192.168.148.116:8899'
            - name: all_proxy
              value: 'socks5://192.168.148.116:8899'
            - name: no_proxy
              value: >-
                127.0.0.1,localhost,10.0.0.0/8,172.16.0.0/12,192.168.0.0/16,.aliyun.com
            - name: HTTP_PROXY
              value: 'http://192.168.148.116:8899'
            - name: HTTPS_PROXY
              value: 'socks5://192.168.148.116:8899'
            - name: ALL_PROXY
              value: 'socks5://192.168.148.116:8899'
            - name: NO_PROXY
              value: >-
                127.0.0.1,localhost,10.0.0.0/8,172.16.0.0/12,192.168.0.0/16,.aliyun.com
```

验证上述代理方式无效，需要注入 jvm args

```bash
-Dhttp.proxyHost=192.168.148.182 -Dhttp.proxyPort=8899 -Dhttps.proxyHost=192.168.148.182 -Dhttps.proxyPort=8899  -Dhttp.nonProxyHosts=127.0.0.1,localhost,10.0.0.0/8,172.16.0.0/12,192.168.0.0/16,open-vsx-es,open-vsx-db,open-vsx.svc.cluster.local,.svc.cluster.local,.cluster.local,.local,.aliyun.com, -Dhttps.proxySet=true -Dhttp.proxySet=true

# 可以通过环境变量 JVM_ARGS 注入
```

给 open-vsx 增加一个 upstream 

```
ovsx.upstream.url = https://open-vsx.org

ovsx.vscode.upstream.gallery-url = https://open-vsx.org/vscode/gallery
```

## 推送插件

推送插件参考：https://github.com/eclipse/openvsx/wiki/Publishing-Extensions#5-package-and-upload

安装推送工具

```bash
npm i -g ovsx
```

使用帮助文档

```bash
npx ovsx --help
Usage: ovsx <command> [options]

Options:
  -r, --registryUrl <url>              Use the registry API at this base URL.
  -p, --pat <token>                    Personal access token.
  --debug                              Include debug information on error
  -V, --version                        Print the Eclipse Open VSX CLI version
  -h, --help                           display help for command

Commands:
  create-namespace <name>              Create a new namespace
  verify-pat [namespace]               Verify that a personal access token can publish to a namespace
  publish [options] [extension.vsix]   Publish an extension, packaging it first if necessary.
  get [options] <namespace.extension>  Download an extension or its metadata.
  help [command]                       display help for command
```

尝试创建 namespace

```bash
root at devmaster1 in ~
# npx ovsx -r https://openvsx.xxx.com -p 71812426-35af-4127-858c-daace3ecbe4f create-namespace jock
🚀  Created namespace jock
```

手动上传插件

```
npx ovsx -r https://openvsx.xxx.com -p 71812426-35af-4127-858c-daace3ecbe4f publish jock.svg-1.4.23.vsix
```

