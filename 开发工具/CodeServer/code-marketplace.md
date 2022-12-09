## 部署

当前最新的构建：<https://github.com/coder/code-marketplace/pkgs/container/code-marketplace>

<img title="" src="../../.assets/2022-12-05-18-32-20-image.png" alt="" data-align="center" width="635">

支持多架构

<img title="" src="../../.assets/2022-12-05-18-32-39-image.png" alt="" data-align="center" width="629">

仓库地址：

```bash
docker pull ghcr.io/coder/code-marketplace:v1.2.1
```

同步到内部仓库地址：

```bash
ghcr.io/coder/code-marketplace:v1.2.1

# 同步至

docker-registry.local.liaosirui.com:5000/third/ghcr.io/coder/code-marketplace:v1.2.1
```

### Helm

提供的 helm chart 部署：<https://github.com/coder/code-marketplace/tree/main/helm>

使用如下的 value:

```yaml
replicaCount: 1
 
image:
  repository: "docker-registry.local.liaosirui.com:5000/third/ghcr.io/coder/code-marketplace"
  pullPolicy: IfNotPresent
  tag: "v1.2.1"
 
imagePullSecrets:
  - system-image-pull-secrets
 
serviceAccount:
  create: true
 
podSecurityContext:
  fsGroup: 1000
 
securityContext:
  capabilities:
    drop:
    - ALL
  readOnlyRootFilesystem: true
  runAsNonRoot: true
  runAsUser: 1000
 
service:
  type: ClusterIP
  port: 80
 
ingress:
  enabled: true
  className: ""
  annotations:
    cert-manager.io/cluster-issuer: letsencrypt
    kubernetes.io/ingress.class: nginx
    nginx.ingress.kubernetes.io/proxy-body-size: 1024m
    nginx.ingress.kubernetes.io/proxy-buffer-size: 256k
  hosts:
    - host: code-marketplace.local.liaosirui.com
      paths:
        - path: /
          pathType: Prefix
  tls:
    - secretName: code-marketplace-tls
      hosts:
        - code-marketplace.local.liaosirui.com
 
resources:
  limits:
    cpu: 100m
    memory: 128Mi
  requests:
    cpu: 100m
    memory: 128Mi
 
autoscaling:
  enabled: false
 
nodeSelector:
  kubernetes.io/os: linux
 
tolerations:
  - key: node-role.kubernetes.io/master
    effect: NoSchedule
  - key: no-pod
    operator: Equal
    value: 'true'
    effect: NoSchedule
  - key: node.kubernetes.io/not-ready
    operator: Exists
    effect: NoExecute
    tolerationSeconds: 300
  - key: node.kubernetes.io/unreachable
    operator: Exists
    effect: NoExecute
    tolerationSeconds: 300
 
affinity:
  podAntiAffinity:
    requiredDuringSchedulingIgnoredDuringExecution:
      - labelSelector:
          matchLabels:
            app.kubernetes.io/name: code-marketplace
        namespaces:
          - code-marketplace
        topologyKey: kubernetes.io/hostname
    requiredDuringSchedulingIgnoredDuringExecution:
      nodeSelectorTerms:
        - matchExpressions:
            - key: kubernetes.io/hostname
              operator: In
              values:
                - devmaster1
                - devmaster2
                - devmaster3

persistence:
  artifactory:
    enabled: false
  size: 100Gi
```

渲染并调整后的部署如下：

### ServiceAccount

```yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: code-marketplace
  namespace: codeserver-system
  labels:
    app.kubernetes.io/name: code-marketplace
    app.kubernetes.io/instance: code-marketplace
    app.kubernetes.io/version: "v1.2.1"

```

### PersistentVolumeClaim

```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: code-marketplace-data
  namespace: codeserver-system
  labels:
    app.kubernetes.io/name: code-marketplace
    app.kubernetes.io/instance: code-marketplace
    app.kubernetes.io/version: "v1.2.1"
spec:
  storageClassName: manual
  accessModes:
    - ReadWriteOnce
  selector:
    matchLabels:
      app.kubernetes.io/name: code-marketplace
      app.kubernetes.io/instance: code-marketplace
      app.kubernetes.io/version: "v1.2.1"
  resources:
    requests:
      storage: "100Gi"
```

### PersistentVolume

```yaml
apiVersion: v1
kind: PersistentVolume
metadata:
  name: code-marketplace-data
  namespace: codeserver-system
  labels:
    app.kubernetes.io/name: code-marketplace
    app.kubernetes.io/instance: code-marketplace
    app.kubernetes.io/version: "v1.2.1"
spec:
  storageClassName: manual
  capacity:
    storage: 100Gi
  accessModes:
    - ReadWriteOnce
  hostPath:
    path: "/mnt/bfs/code-server/code-marketplace"
  nodeAffinity:
    required:
      nodeSelectorTerms:
        - matchExpressions:
            - key: kubernetes.io/hostname
              operator: In
              values:
                - monitoring-node01
```

### Service

```yaml
apiVersion: v1
kind: Service
metadata:
  name: code-marketplace
  namespace: codeserver-system
  labels:
    app.kubernetes.io/name: code-marketplace
    app.kubernetes.io/instance: code-marketplace
    app.kubernetes.io/version: "v1.2.1"
spec:
  type: ClusterIP
  ports:
    - port: 80
      targetPort: http
      protocol: TCP
      name: http
  selector:
    app.kubernetes.io/name: code-marketplace
    app.kubernetes.io/instance: code-marketplace
```

### Deployment

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: code-marketplace
  namespace: codeserver-system
  labels:
    app.kubernetes.io/name: code-marketplace
    app.kubernetes.io/instance: code-marketplace
    app.kubernetes.io/version: "v1.2.1"
spec:
  replicas: 1
  selector:
    matchLabels:
      app.kubernetes.io/name: code-marketplace
      app.kubernetes.io/instance: code-marketplace
  template:
    metadata:
      labels:
        app.kubernetes.io/name: code-marketplace
        app.kubernetes.io/instance: code-marketplace
    spec:
      imagePullSecrets:
        - name: aipaas-image-pull-secrets
      serviceAccountName: code-marketplace
      volumes:
        - name: extensions
          persistentVolumeClaim:
            claimName: code-marketplace-data
      securityContext:
        fsGroup: 1000
      containers:
        - name: code-marketplace
          securityContext:
            capabilities:
              drop:
              - ALL
            readOnlyRootFilesystem: true
            runAsNonRoot: true
            runAsUser: 1000
          image: "docker-registry.local.liaosirui.com:5000/third/ghcr.io/coder/code-marketplace:v1.2.1"
          imagePullPolicy: IfNotPresent
          ports:
            - name: http
              containerPort: 10080
              protocol: TCP
          args:
            - --address
            - 0.0.0.0:10080
            - --extensions-dir
            - /extensions
          volumeMounts:
            - name: extensions
              mountPath: /extensions
          livenessProbe:
            httpGet:
              path: /healthz
              port: http
          readinessProbe:
            httpGet:
              path: /healthz
              port: http
          resources:
            limits:
              cpu: 100m
              memory: 128Mi
            requests:
              cpu: 100m
              memory: 128Mi
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
                    app.kubernetes.io/instance: code-marketplace
                namespaces:
                  - codeserver-system
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
```

### Secret

```yaml
apiVersion: v1
kind: Secret
type: kubernetes.io/tls
metadata:
  name: code-marketplace-tls
  namespace: codeserver-system
  labels:
    app.kubernetes.io/name: code-marketplace
    app.kubernetes.io/instance: code-marketplace
    app.kubernetes.io/version: "v1.2.1"
stringData:
  tls.crt: |
    -----BEGIN CERTIFICATE-----
    MIIFNTCCBB2gAwIBAgISAwq4tz0n9uy24c9Cjxq1e0twMA0GCSqGSIb3DQEBCwUA
    MDIxCzAJBgNVBAYTAlVTMRYwFAYDVQQKEw1MZXQncyBFbmNyeXB0MQswCQYDVQQD
    EwJSMzAeFw0yMjEyMDUwNzIyMzFaFw0yMzAzMDUwNzIyMzBaMCMxITAfBgNVBAMT
    GG1hcmtldHBsYWNlLmJpZ3F1YW50LmNvbTCCASIwDQYJKoZIhvcNAQEBBQADggEP
    ADCCAQoCggEBAKzEKNN0GtdNzlJrzd9fSwEDrY2K/vrkh5jTIx2eqwcaAiEibIiX
    N8qeaLBoOrP9TsbdbLZmnGRPAHjDpwWmgc6Za6Ou0OV/QF199mWr+nQLn+mnTZW9
    6dZo2CYhtcxZkLo6SSXBavlWjK2j7NIXOWAJs1VoekRAn4fmIc0UO0G9uFqtdZff
    ZIUGuo6RvYqeG2OQWAHIz7Pirn17+mGRD3Cv/5XpJYAXeChm5Jj7qLYt1C0DbQuW
    dw82V9uI/XMaz123M1xxFYXSyuXk5mkGlngJP15dUd4xpR8tXyb+/JD6qTS2Ng6S
    px1w9DZKOn/F52fLSfmXofV5C68Dy8lDqWsCAwEAAaOCAlIwggJOMA4GA1UdDwEB
    /wQEAwIFoDAdBgNVHSUEFjAUBggrBgEFBQcDAQYIKwYBBQUHAwIwDAYDVR0TAQH/
    BAIwADAdBgNVHQ4EFgQUoudrgdCxjQB3kBQMrPViDdegdMYwHwYDVR0jBBgwFoAU
    FC6zF7dYVsuuUAlA5h+vnYsUwsYwVQYIKwYBBQUHAQEESTBHMCEGCCsGAQUFBzAB
    hhVodHRwOi8vcjMuby5sZW5jci5vcmcwIgYIKwYBBQUHMAKGFmh0dHA6Ly9yMy5p
    LmxlbmNyLm9yZy8wIwYDVR0RBBwwGoIYbWFya2V0cGxhY2UuYmlncXVhbnQuY29t
    MEwGA1UdIARFMEMwCAYGZ4EMAQIBMDcGCysGAQQBgt8TAQEBMCgwJgYIKwYBBQUH
    AgEWGmh0dHA6Ly9jcHMubGV0c2VuY3J5cHQub3JnMIIBAwYKKwYBBAHWeQIEAgSB
    9ASB8QDvAHYAejKMVNi3LbYg6jjgUh7phBZwMhOFTTvSK8E6V6NS61IAAAGE4WEo
    IAAABAMARzBFAiEA7kxVJ1ogXw1yWmjzoYpTLHStkd0AZ/GNKvifwtIjD0ECIDf2
    vPn2xufmZcAi95SX/jK6p8y8wRKWHnmSo8kjPoQpAHUA6D7Q2j71BjUy51covIlr
    yQPTy9ERa+zraeF3fW0GvW4AAAGE4WEoDQAABAMARjBEAiAblgHfdMsdUVP/eugZ
    pEh1fn/sUN8z1KMuhQpYm3UiUgIgTNINGU4x20d6PKfEHiF4d9Z3W1cqibHuGQuq
    Q66sTXswDQYJKoZIhvcNAQELBQADggEBALLLl4pLp3kUdhbFt6vjyD9ign4aPySH
    g7Tepdamhv8Au1xtzPbq2DQ0fAkjszfPPgQ0uDmUYflfJDmQNqXelX/mR15v8Otc
    8gFayEDfblSMyDjCXygV1bDskJscfehXVa70Mc5MQvjree+UWh3k1FhTpm1cCcQl
    I+4w3naDKzxq7lvjtBO+vvWS06lHm6Mi15MP0tMz52IXL8oulaMsmvpqFmPqfrrv
    tzK3dJTm4BmyY/fnypNq+BrqHQbOubs6CA50j2pJJJZh9I1hcauXW9zTgLS/19Eq
    t/AAaJOfFcfdHo7dk78p/KBq157BMd/JDafVvNIMkxJ/svGyMW2sDHw=
    -----END CERTIFICATE-----
    -----BEGIN CERTIFICATE-----
    MIIFFjCCAv6gAwIBAgIRAJErCErPDBinU/bWLiWnX1owDQYJKoZIhvcNAQELBQAw
    TzELMAkGA1UEBhMCVVMxKTAnBgNVBAoTIEludGVybmV0IFNlY3VyaXR5IFJlc2Vh
    cmNoIEdyb3VwMRUwEwYDVQQDEwxJU1JHIFJvb3QgWDEwHhcNMjAwOTA0MDAwMDAw
    WhcNMjUwOTE1MTYwMDAwWjAyMQswCQYDVQQGEwJVUzEWMBQGA1UEChMNTGV0J3Mg
    RW5jcnlwdDELMAkGA1UEAxMCUjMwggEiMA0GCSqGSIb3DQEBAQUAA4IBDwAwggEK
    AoIBAQC7AhUozPaglNMPEuyNVZLD+ILxmaZ6QoinXSaqtSu5xUyxr45r+XXIo9cP
    R5QUVTVXjJ6oojkZ9YI8QqlObvU7wy7bjcCwXPNZOOftz2nwWgsbvsCUJCWH+jdx
    sxPnHKzhm+/b5DtFUkWWqcFTzjTIUu61ru2P3mBw4qVUq7ZtDpelQDRrK9O8Zutm
    NHz6a4uPVymZ+DAXXbpyb/uBxa3Shlg9F8fnCbvxK/eG3MHacV3URuPMrSXBiLxg
    Z3Vms/EY96Jc5lP/Ooi2R6X/ExjqmAl3P51T+c8B5fWmcBcUr2Ok/5mzk53cU6cG
    /kiFHaFpriV1uxPMUgP17VGhi9sVAgMBAAGjggEIMIIBBDAOBgNVHQ8BAf8EBAMC
    AYYwHQYDVR0lBBYwFAYIKwYBBQUHAwIGCCsGAQUFBwMBMBIGA1UdEwEB/wQIMAYB
    Af8CAQAwHQYDVR0OBBYEFBQusxe3WFbLrlAJQOYfr52LFMLGMB8GA1UdIwQYMBaA
    FHm0WeZ7tuXkAXOACIjIGlj26ZtuMDIGCCsGAQUFBwEBBCYwJDAiBggrBgEFBQcw
    AoYWaHR0cDovL3gxLmkubGVuY3Iub3JnLzAnBgNVHR8EIDAeMBygGqAYhhZodHRw
    Oi8veDEuYy5sZW5jci5vcmcvMCIGA1UdIAQbMBkwCAYGZ4EMAQIBMA0GCysGAQQB
    gt8TAQEBMA0GCSqGSIb3DQEBCwUAA4ICAQCFyk5HPqP3hUSFvNVneLKYY611TR6W
    PTNlclQtgaDqw+34IL9fzLdwALduO/ZelN7kIJ+m74uyA+eitRY8kc607TkC53wl
    ikfmZW4/RvTZ8M6UK+5UzhK8jCdLuMGYL6KvzXGRSgi3yLgjewQtCPkIVz6D2QQz
    CkcheAmCJ8MqyJu5zlzyZMjAvnnAT45tRAxekrsu94sQ4egdRCnbWSDtY7kh+BIm
    lJNXoB1lBMEKIq4QDUOXoRgffuDghje1WrG9ML+Hbisq/yFOGwXD9RiX8F6sw6W4
    avAuvDszue5L3sz85K+EC4Y/wFVDNvZo4TYXao6Z0f+lQKc0t8DQYzk1OXVu8rp2
    yJMC6alLbBfODALZvYH7n7do1AZls4I9d1P4jnkDrQoxB3UqQ9hVl3LEKQ73xF1O
    yK5GhDDX8oVfGKF5u+decIsH4YaTw7mP3GFxJSqv3+0lUFJoi5Lc5da149p90Ids
    hCExroL1+7mryIkXPeFM5TgO9r0rvZaBFOvV2z0gp35Z0+L4WPlbuEjN/lxPFin+
    HlUjr8gRsI3qfJOQFy/9rKIJR0Y/8Omwt/8oTWgy1mdeHmmjk7j1nYsvC9JSQ6Zv
    MldlTTKB3zhThV1+XWYp6rjd5JW1zbVWEkLNxE7GJThEUG3szgBVGP7pSWTUTsqX
    nLRbwHOoq7hHwg==
    -----END CERTIFICATE-----
    -----BEGIN CERTIFICATE-----
    MIIFYDCCBEigAwIBAgIQQAF3ITfU6UK47naqPGQKtzANBgkqhkiG9w0BAQsFADA/
    MSQwIgYDVQQKExtEaWdpdGFsIFNpZ25hdHVyZSBUcnVzdCBDby4xFzAVBgNVBAMT
    DkRTVCBSb290IENBIFgzMB4XDTIxMDEyMDE5MTQwM1oXDTI0MDkzMDE4MTQwM1ow
    TzELMAkGA1UEBhMCVVMxKTAnBgNVBAoTIEludGVybmV0IFNlY3VyaXR5IFJlc2Vh
    cmNoIEdyb3VwMRUwEwYDVQQDEwxJU1JHIFJvb3QgWDEwggIiMA0GCSqGSIb3DQEB
    AQUAA4ICDwAwggIKAoICAQCt6CRz9BQ385ueK1coHIe+3LffOJCMbjzmV6B493XC
    ov71am72AE8o295ohmxEk7axY/0UEmu/H9LqMZshftEzPLpI9d1537O4/xLxIZpL
    wYqGcWlKZmZsj348cL+tKSIG8+TA5oCu4kuPt5l+lAOf00eXfJlII1PoOK5PCm+D
    LtFJV4yAdLbaL9A4jXsDcCEbdfIwPPqPrt3aY6vrFk/CjhFLfs8L6P+1dy70sntK
    4EwSJQxwjQMpoOFTJOwT2e4ZvxCzSow/iaNhUd6shweU9GNx7C7ib1uYgeGJXDR5
    bHbvO5BieebbpJovJsXQEOEO3tkQjhb7t/eo98flAgeYjzYIlefiN5YNNnWe+w5y
    sR2bvAP5SQXYgd0FtCrWQemsAXaVCg/Y39W9Eh81LygXbNKYwagJZHduRze6zqxZ
    Xmidf3LWicUGQSk+WT7dJvUkyRGnWqNMQB9GoZm1pzpRboY7nn1ypxIFeFntPlF4
    FQsDj43QLwWyPntKHEtzBRL8xurgUBN8Q5N0s8p0544fAQjQMNRbcTa0B7rBMDBc
    SLeCO5imfWCKoqMpgsy6vYMEG6KDA0Gh1gXxG8K28Kh8hjtGqEgqiNx2mna/H2ql
    PRmP6zjzZN7IKw0KKP/32+IVQtQi0Cdd4Xn+GOdwiK1O5tmLOsbdJ1Fu/7xk9TND
    TwIDAQABo4IBRjCCAUIwDwYDVR0TAQH/BAUwAwEB/zAOBgNVHQ8BAf8EBAMCAQYw
    SwYIKwYBBQUHAQEEPzA9MDsGCCsGAQUFBzAChi9odHRwOi8vYXBwcy5pZGVudHJ1
    c3QuY29tL3Jvb3RzL2RzdHJvb3RjYXgzLnA3YzAfBgNVHSMEGDAWgBTEp7Gkeyxx
    +tvhS5B1/8QVYIWJEDBUBgNVHSAETTBLMAgGBmeBDAECATA/BgsrBgEEAYLfEwEB
    ATAwMC4GCCsGAQUFBwIBFiJodHRwOi8vY3BzLnJvb3QteDEubGV0c2VuY3J5cHQu
    b3JnMDwGA1UdHwQ1MDMwMaAvoC2GK2h0dHA6Ly9jcmwuaWRlbnRydXN0LmNvbS9E
    U1RST09UQ0FYM0NSTC5jcmwwHQYDVR0OBBYEFHm0WeZ7tuXkAXOACIjIGlj26Ztu
    MA0GCSqGSIb3DQEBCwUAA4IBAQAKcwBslm7/DlLQrt2M51oGrS+o44+/yQoDFVDC
    5WxCu2+b9LRPwkSICHXM6webFGJueN7sJ7o5XPWioW5WlHAQU7G75K/QosMrAdSW
    9MUgNTP52GE24HGNtLi1qoJFlcDyqSMo59ahy2cI2qBDLKobkx/J3vWraV0T9VuG
    WCLKTVXkcGdtwlfFRjlBz4pYg1htmf5X6DYO8A4jqv2Il9DjXA6USbW1FzXSLr9O
    he8Y4IWS6wY7bCkjCWDcRQJMEhg76fsO3txE+FiYruq9RUWhiF1myv4Q6W+CyBFC
    Dfvp7OOGAN6dEOM4+qR9sdjoSYKEBpsr6GtPAQw4dy753ec5
    -----END CERTIFICATE-----
  tls.key: |
    -----BEGIN RSA PRIVATE KEY-----
    MIIEpAIBAAKCAQEArMQo03Qa103OUmvN319LAQOtjYr++uSHmNMjHZ6rBxoCISJs
    iJc3yp5osGg6s/1Oxt1stmacZE8AeMOnBaaBzplro67Q5X9AXX32Zav6dAuf6adN
    lb3p1mjYJiG1zFmQujpJJcFq+VaMraPs0hc5YAmzVWh6RECfh+YhzRQ7Qb24Wq11
    l99khQa6jpG9ip4bY5BYAcjPs+KufXv6YZEPcK//leklgBd4KGbkmPuoti3ULQNt
    C5Z3DzZX24j9cxrPXbczXHEVhdLK5eTmaQaWeAk/Xl1R3jGlHy1fJv78kPqpNLY2
    DpKnHXD0Nko6f8XnZ8tJ+Zeh9XkLrwPLyUOpawIDAQABAoIBADhuAd+/Rp0YftGR
    ALd7CqaUKvXWdp5AUsHqBMhB8R7qsdNcyRJ8Qe7eetdT1AjCLh7qZ/3T2jUxULgh
    P8aqsi9nES9vhC/RtpZS9E4VNEL/IQZSbRcB5wTvTdp2nEjY4FrTetzoJia2zFBT
    AKFGkKj7wiWdcIImkXT0CApSF2DLKyxfKTCZzPSAx7aMdJSSRnFQEJntJImtH1hE
    TuERvjnz3y1EBSLfB7YKTKQMEaugXFSZ+sjBUhN2+YPg44DTdAWyYoKcu/tg7OZr
    drVu9xGkAq5ykCKDG0YBy0goYjjll9eXpX1tcaAlaWs3JaEPCwAXZqP1WZXdL2j1
    wfv+KxECgYEA5Un3tQXao5sJZCjDb+bN2GnhX2v/5X/NrD1ciH6v410iE6dExTaG
    7GRq/snyFXhdyOw+D+2lvC7rFmBGdigjDinYa1v8QY6qIENyKQtNLMlAN+j/jQmQ
    Im+yer7quQFEfGiQecWWLKZYr5yv636Gsy+GpPs89w9faD2DgqxKyM8CgYEAwOSH
    SKVPGQCYhLAkhB0wl+QaV6MuqKIKIzevCbp/ZtLs43mwqlo1vogjwwDNqaIBy4XF
    rpk9NiSRnMSvV10QC7gQJYkEKiR/XizDwx6nruVOfZxKb4xVklzaSa2dQ8LmRCzz
    qTutJuYWmU/a7SbWuiZlbZT+QHiFKTGsKjCDBKUCgYEA15zi7rt+inL0NdePUN89
    mtCWOmEY1fuEsP9S0JgxViDyNoEIzlskLY+Qfd/xYfc6WgKtqdTUEU4di4ElQV8k
    9+CpvutVH2DE4moKJEaYYBEv7mOQTFQ90eQvdfWqTCbA/CxoD9qaCYqzwxAY7d6h
    VEbQ2rvW7IzsLt4JmQvjl0kCgYAa3DfSb+KR0rlqULTlCMOJgyP/7CNFLDtJKCnh
    quyuvtRp4LovHpy5SW/haa053+tsEdazN3eEoJb+Q40/FyBy4VCuSWQhEjACRy2D
    cDNdcWT6rNbYrawE05U6CUkK9IroF3JesIauEgA3nR0ZRP1Fsq8REVxOUfoJAHe+
    8D5uWQKBgQC9LFP2eG2U/XBDk+vRMMqivIklf00CB7i8lzsZ9q4PnjK6hENUdovQ
    zRAAjMTQ9mflmTeoPTgyCx92sQJoZSRhnLng1ElzWpo/rkSpTJx5mz9xhfeoQ6JG
    ieBgVwg0aayF+vJHBuDQn1k5LaWQRWidSfR+1jZLV2dFhNnO1+mEZw==
    -----END RSA PRIVATE KEY-----

```

### Ingress

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: code-marketplace
  namespace: codeserver-system
  labels:
    app.kubernetes.io/name: code-marketplace
    app.kubernetes.io/instance: code-marketplace
    app.kubernetes.io/version: "v1.2.1"
  annotations:
    kubernetes.io/ingress.class: nginx
    nginx.ingress.kubernetes.io/proxy-body-size: 1024m
    nginx.ingress.kubernetes.io/proxy-buffer-size: 256k
 
spec:
  tls:
    - hosts:
        - "code-marketplace.local.liaosirui.com"
      secretName: code-marketplace-tls
  rules:
    - host: "code-marketplace.local.liaosirui.com"
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: code-marketplace
                port:
                  name: http
```

## 使用

同步一个构建至仓库中：

```bash
./code-marketplace add extension.vsix [flags]
./code-marketplace add extension-vsixs/ [flags]
./code-marketplace add https://domain.tld/extension.vsix [flags]
./code-marketplace add https://open-vsx.org/api/ms-python/python/2022.14.0/file/ms-python.python-2022.14.0.vsix [flags]
./code-marketplace add https://github.com/VSCodeVim/Vim/releases/download/v1.24.1/vim-1.24.1.vsix [flags]
```

移除一个构建：

```bash
./code-marketplace remove ms-python.python-2022.14.0
 
./code-marketplace remove ms-python.python --all
```

code-server 中如何使用：

```

export EXTENSIONS_GALLERY='{"serviceUrl":"https://<domain>/api", "itemUrl":"https://<domain>/item", "resourceUrlTemplate": "https://<domain>/files/{publisher}/{name}/{version}/{path}"}'
 
code-server
```

本次部署中的实例使用方式

```bash
ENV \
 EXTENSIONS_GALLERY='{"serviceUrl":"https://marketplace.code-marketplace.com/api", "itemUrl":"https://marketplace.code-marketplace.com/item", "resourceUrlTemplate": "https://marketplace.code-marketplace.com/files/{publisher}/{name}/{version}/{path}"}'


      env:
        - name: EXTENSIONS_GALLERY
          value: '{"serviceUrl":"https://marketplace.code-marketplace.com/api", "itemUrl":"https://marketplace.code-marketplace.com/item", "resourceUrlTemplate": "https://marketplace.code-marketplace.com/files/{publisher}/{name}/{version}/{path}"}'

```

