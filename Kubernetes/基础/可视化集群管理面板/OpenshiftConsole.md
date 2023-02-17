部署 ns

```yaml
apiVersion: v1
kind: Namespace
metadata:
  name: openshift-console
```

部署 RBAC

```yaml
---
apiVersion: v1
kind: ServiceAccount
metadata:
  name: console
  namespace: openshift-console
automountServiceAccountToken: true
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: console
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: cluster-admin
subjects:
- kind: ServiceAccount
  name: console
  namespace: openshift-console
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: cluster-admin
rules:
- apiGroups:
  - '*'
  resources:
  - '*'
  verbs:
  - '*'
- nonResourceURLs:
  - '*'
  verbs:
  - '*'

```

创建一个 token secret

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: console-sa-secret
  namespace: openshift-console
  annotations:
    kubernetes.io/service-account.name: console
type: kubernetes.io/service-account-token
```

部署 deployment

```yaml
kind: Deployment
apiVersion: apps/v1
metadata:
  name: console-deployment
  namespace: openshift-console
  labels:
    app: console
spec:
  replicas: 1
  selector:
    matchLabels:
      app: console
  template:
    metadata:
      labels:
        app: console
    spec:
      nodeSelector:
        console: "true"
      serviceAccountName: console
      tolerations:
        - operator: "Exists"
      containers:
        - name: console-app
          image: 'quay.io/openshift/origin-console:4.13.0'
          ports:
          - name: http
            containerPort: 9000
            protocol: TCP
            hostPort: 19000
          env:
            - name: BRIDGE_USER_AUTH
              value: disabled
            - name: BRIDGE_K8S_MODE
              value: off-cluster
            - name: BRIDGE_K8S_MODE_OFF_CLUSTER_ENDPOINT
              value: 'https://kubernetes.default'
            - name: BRIDGE_K8S_MODE_OFF_CLUSTER_SKIP_VERIFY_TLS
              value: 'true'
            - name: BRIDGE_K8S_AUTH
              value: bearer-token
            - name: BRIDGE_K8S_AUTH_BEARER_TOKEN
              valueFrom:
                secretKeyRef:
                  name: console-sa-secret
                  key: token
          resources:
            limits: {}
            requests: {}
          imagePullPolicy: IfNotPresent
      restartPolicy: Always
      dnsPolicy: ClusterFirst
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxUnavailable: 25%
      maxSurge: 25%
  revisionHistoryLimit: 10
  progressDeadlineSeconds: 600

```

建立一个 service 方便后期使用

```yaml
apiVersion: v1
kind: Service
metadata:
  name: console-service
  namespace: openshift-console
spec:
  clusterIP: None
  type: ClusterIP
  selector:
    app: console
  ports:
    - port: 9000
      targetPort: 9000
```

如果使用 NodePort

```yaml
```

