代码地址：<https://github.com/istio/istio/tree/master/samples/bookinfo/>

安装官方的 Demo 示例：

```bash
kubectl create ns istio-bookinfo-demo

kubectl label namespace istio-bookinfo-demo istio-injection=enabled

kubectl apply \
-n istio-bookinfo-demo \
-f libs/istio/samples/bookinfo/platform/kube/bookinfo.yaml
```

应用很快会启动起来。当每个 Pod 准备就绪时，Istio 边车将伴随应用一起部署

```bash
kubectl get all -n istio-bookinfo-demo
```

确认上面的操作都正确之后，运行下面命令，通过检查返回的页面标题来验证应用是否已在集群中运行，并已提供网页服务：

```bash
kubectl exec -n istio-bookinfo-demo "$(kubectl get pod -n istio-bookinfo-demo -l app=ratings -o jsonpath='{.items[0].metadata.name}')" -c ratings -- curl -sS productpage:9080/productpage | grep -o "<title>.*</title>"

```

此时，BookInfo 应用已经部署，但还不能被外界访问。要开放访问，需要创建 Istio 入站网关（Ingress Gateway）， 它会在网格边缘把一个路径映射到路由

```bash
kubectl apply \
-n istio-bookinfo-demo \
-f libs/istio/samples/bookinfo/networking/bookinfo-gateway.yaml
```

检查配置

```bash
> istioctl analyze

Error [IST0101] (Gateway istio-bookinfo-demo/bookinfo-gateway) Referenced selector not found: "istio=ingressgateway"
Error: Analyzers found issues when analyzing namespace: istio-bookinfo-demo.
See https://istio.io/v1.19/docs/reference/config/analysis for more information about causes and resolutions.
```

切换 gateway 对应的 selector

```yaml
apiVersion: networking.istio.io/v1alpha3
kind: Gateway
metadata:
  name: bookinfo-gateway
spec:
  selector:
    istio: ingress-istio-gateway # use istio default controller
  servers:
  - port:
      number: 80
      name: http
      protocol: HTTP
    hosts:
    - "*"

```

执行下面命令以判断的 Kubernetes 集群环境是否支持外部负载均衡：

```bash
> kubectl get svc -n ingress-istio-gateway ingress-istio-gateway

NAME                    TYPE       CLUSTER-IP   EXTERNAL-IP   PORT(S)                                      AGE
ingress-istio-gateway   NodePort   10.96.2.92   <none>        15021:31868/TCP,80:30621/TCP,443:30934/TCP   65m
```

设置 `EXTERNAL-IP` 的值之后， 环境就有了一个外部的负载均衡器，可以将其用作入站网关。但如果 EXTERNAL-IP 的值为 (或者一直是 <`pending`> 状态)， 则环境则没有提供可作为入站流量网关的外部负载均衡器

在这个情况下，还可以用服务（Service）的`NodePort`访问网关

```bash
export INGRESS_PORT=$(kubectl get service -n ingress-istio-gateway ingress-istio-gateway -o jsonpath='{.spec.ports[?(@.name=="http2")].nodePort}')

export INGRESS_HOST=$(kubectl get po -l istio=ingress-istio-gateway -n ingress-istio-gateway -o jsonpath='{.items[0].status.hostIP}')
```

设置环境变量 GATEWAY_URL：

```bash
export GATEWAY_URL=$INGRESS_HOST:$INGRESS_PORT
echo "$GATEWAY_URL"
echo "http://$GATEWAY_URL/productpage"
```

把上面命令的输出地址复制粘贴到浏览器并访问，确认 Bookinfo 应用的产品页面是否可以打开