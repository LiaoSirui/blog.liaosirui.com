## OKD 简介

红帽 OpenShift 的开源社区版本称为 OKD（The Origin Community Distribution of Kubernetes，或 OpenShift Kubernetes Distribution 的缩写，原名 OpenShift Origin），是 Red Hat OpenShift Container Platform (OCP) 的上游和社区支持版本

## 部署 OKD Web 控制台

创建一个特定的服务帐户

```bash
kubectl create serviceaccount okd-console \
  -n kube-system

kubectl create clusterrolebinding okd-console \
  --clusterrole=cluster-admin \
  --serviceaccount=kube-system:okd-console \
  -n kube-system
```

如果没有 cluster-admin，则创建：
```yaml
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: cluster-admin
rules:
  - apiGroups:
      - "*"
    resources:
      - "*"
    verbs:
      - "*"
  - nonResourceURLs:
      - "*"
    verbs:
      - "*"

```

提取与控制台服务帐户关联的令牌秘密名称

```bash
# 提取与控制台服务帐户关联的令牌秘密名称
kubectl get serviceaccount okd-console \
  -n kube-system \
  -o jsonpath='{.secrets[0].name}'

# 写入 okd-web-console-install.yaml
# console serviceaccount token: console-token-rzws4
```

也可以选择创建一个 token secret
```yaml
apiVersion: v1
kind: Secret
metadata:
  name: okd-console-sa-secret
  namespace: kube-system
  annotations:
    kubernetes.io/service-account.name: okd-console
type: kubernetes.io/service-account-token
```


创建 `okd-web-console-install.yaml` 文件，并部署服务

```yaml
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: okd-console
  namespace: kube-system
  labels:
    app: okd-console
spec:
  replicas: 1
  selector:
    matchLabels:
      app: okd-console
  template:
    metadata:
      labels:
        app: okd-console
    spec:
      nodeSelector:
        console: "true"
      serviceAccountName: console
      tolerations:
        - operator: "Exists"
      containers:
        - name: console
          image: "quay.io/openshift/origin-console:4.12.0"
          imagePullPolicy: IfNotPresent
          resources:
            # requests:
            #   cpu: "2"
            #   memory: 4Gi
            limits:
              cpu: "2"
              memory: 4Gi
          ports:
            - name: http
              containerPort: 9000
              protocol: TCP
              # hostPort: 19000
          env:
            - name: BRIDGE_USER_AUTH
              value: disabled # no authentication required
            - name: BRIDGE_K8S_MODE
              value: off-cluster
            - name: BRIDGE_K8S_MODE_OFF_CLUSTER_ENDPOINT
              value: "https://kubernetes.default" # master api
            - name: BRIDGE_K8S_MODE_OFF_CLUSTER_SKIP_VERIFY_TLS
              value: "true" # no tls enabled
            - name: BRIDGE_PLUGINS
              value: 
            - name: BRIDGE_K8S_AUTH
              value: bearer-token
            - name: BRIDGE_K8S_AUTH_BEARER_TOKEN
              valueFrom:
                secretKeyRef:
                  name: okd-console-token-rzws4 # console serviceaccount token
                  key: token

---
kind: Service
apiVersion: v1
metadata:
  name: okd-console
  namespace: kube-system
spec:
  selector:
    app: okd-console
  type: NodePort # nodeport configuration
  ports:
    - name: http
      port: 9000
      targetPort: 9000
      nodePort: 30037
      protocol: TCP

```

部署成功后, 浏览器访问 30037 端口即可

如果遇到错误：

```plain
W0515 05:41:26.001941 1 main.go:226] Flag inactivity-timeout is set to less then 300 seconds and will be ignored!
W0515 05:41:26.002001 1 main.go:373] cookies are not secure because base-address is not https!
W0515 05:41:26.002040 1 main.go:717] running with AUTHENTICATION DISABLED!
I0515 05:41:26.003630 1 main.go:835] Binding to 0.0.0.0:9000...
I0515 05:41:26.003665 1 main.go:840] not using TLS
I0515 05:41:29.004340 1 metrics.go:141] serverconfig.Metrics: Update ConsolePlugin metrics...
panic: runtime error: invalid memory address or nil pointer dereference
[signal SIGSEGV: segmentation violation code=0x1 addr=0x0 pc=0x2c9fd99]
goroutine 94 [running]:
github.com/openshift/console/pkg/serverconfig.(*Metrics).getConsolePlugins(0x0?, 0x0?, {0xc000504280?, 0xc000497ea0?}, {0xc00006001d?, 0x1?})
/go/src/github.com/openshift/console/pkg/serverconfig/metrics.go:181 +0x199
github.com/openshift/console/pkg/serverconfig.(*Metrics).updatePluginMetric(0xc0003fc540, 0xc0004867d0?, {0xc000504280, 0x1a}, {0xc00006001d, 0x38c})
/go/src/github.com/openshift/console/pkg/serverconfig/metrics.go:144 +0xf1
created by github.com/openshift/console/pkg/serverconfig.(*Metrics).MonitorPlugins.func1
/go/src/github.com/openshift/console/pkg/serverconfig/metrics.go:116 +0x105
```

可部署：<https://github.com/openshift/api/blob/release-4.12/console/v1/0000_10_consoleplugin.crd.yaml>
