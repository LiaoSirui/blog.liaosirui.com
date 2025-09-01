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
          image: "quay.io/openshift/origin-console:4.20.0"
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

可部署：<https://github.com/openshift/api/blob/release-4.12/console/v1/0000_10_consoleplugin.crd.yaml>
