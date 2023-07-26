istio-ingressgateway 作为服务访问的最外层，还需要做一些 ssl 加密的工作，同时又不会影响其它的服务。

## 文件挂载方式

查看 istio-ingressgateway 配置中的证书挂载配置

```yaml
volumeMounts:
...
	# 证书目录
  - name: ingressgateway-certs
    readOnly: true
    mountPath: /etc/istio/ingressgateway-certs
  - name: ingressgateway-ca-certs
    readOnly: true
    mountPath: /etc/istio/ingressgateway-ca-certs
```

引用的 volume 如下：

```yaml
volumes:
...
  - name: ingressgateway-certs
    secret:
      secretName: istio-ingressgateway-certs
      defaultMode: 420
      optional: true
  - name: ingressgateway-ca-certs
    secret:
      secretName: istio-ingressgateway-ca-certs
      defaultMode: 420
      optional: true
```

istio-ingressgateway 默认配置了一个挂载 secret 证书的方式，但是这个 secret 不会创建，需要把自己的证书生成 istio 下的 secret，名称和定义中的一致 istio-ingressgateway-certs，istio 网关将会自动加载该 secret

- 创建 ingressgateway-certs

```bash
kubectl create -n istio-system secret tls istio-ingressgateway-certs --key ssl/server.key --cert ssl/server.pem 
```

- 查看 ingressgateway 是否挂载了证书

```bash
kubectl get pod -n istio-system |grep ingress

kubectl exec -it -n istio-system pod/istio-ingressgateway-7bd5586b79-pgrmd ls /etc/istio/ingressgateway-certs
```

- 修改 gateway 配置

```yaml
apiVersion: networking.istio.io/v1beta1
kind: Gateway
metadata:
  name: kubeflow-gateway
  namespace: kubeflow
spec:
  selector:
    istio: ingressgateway
  servers:
    - hosts:
        - '*'
      port:
        name: http
        number: 80
        protocol: HTTP
      # 添加tls，此处引用 ingressgateway 本地证书文件
      tls:
        mode: SIMPLE
        serverCertificate: /etc/istio/ingressgateway-certs/tls.crt
        privateKey: /etc/istio/ingressgateway-certs/tls.key
```

## 通过 SDS 方式



