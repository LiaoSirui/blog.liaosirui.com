## Istio Egress 简介

官方文档：

- <https://istio.io/latest/zh/docs/tasks/traffic-management/egress/egress-control/>

istio-egressgateway 也是 Istio 中的一种组件，需要自行安装。安装 istio-egressgateway 命令：

```bash
helm install istio-egressgateway istio/gateway -n istio-system
```

在集群中，如果 A 应用访问的地址属于集群中的应用，那么 Istio 可以给这些请求注入各种行为，实现负载均衡和熔断等

可是，如果集群内部要访问外部的一个服务时，需要配置访问地址，如 aaa.com，我们应该如何实现负载均衡和熔断这些功能呢？

![image-20230515195151940](.assets/egress/image-20230515195151940.png)

Istio ServiceEntry 是一种资源，允许将外部服务（即不在 Istio 服务网格中的服务）纳入Istio服务网格。通过将外部服务添加到网格，可以使用 Istio 的流量管理和策略功能来控制与这些外部服务的交互。

以下是一个ServiceEntry示例，将外部HTTP服务`www.google.com`添加到Istio服务网格：

```yaml
apiVersion: networking.istio.io/v1alpha3  
kind: ServiceEntry  
metadata:  
  name: google
spec:  
  hosts:  
  - www.google.com  
  addresses:  
  - 192.168.1.1  
  ports:  
  - number: 80  
    name: http  
    protocol: HTTP  
  location: MESH_EXTERNAL  
  resolution: DNS  
  endpoints:  
  - address: "www.google.com"  
    ports:  
      http: 80  
    locality: "us-west1/zone1"  
  exportTo:  
  - "*"

```

在此示例中，我们创建了一个名为`httpbin-ext`的ServiceEntry资源。指定的主机为`httpbin.org`，端口号为80，协议为HTTP。此外，将`resolution`设置为`DNS`，将`location`设置为`MESH_EXTERNAL`，表示该服务位于网格之外

现在，Istio 服务网格中的服务访问 `www.google.com` 时仍受Istio策略的控制。例如，可以为此 ServiceEntry 创建 VirtualService 以应用流量管理规则，或者为其创建 DestinationRule 以配置负载均衡和连接池设置。

`spec`: 包含ServiceEntry的具体配置的对象。

- `hosts`: 一个包含要导入的外部服务的主机名（FQDN）的列表。例如：`["httpbin.org"]`。
- `addresses`: （可选）与外部服务关联的虚拟IP地址的列表。例如：`["192.168.1.1"]`。
- ports: 一个描述外部服务使用的端口的列表。每个端口都有以下属性：
  - `number`: 端口号，例如：80。
  - `name`: 端口的名称，例如：`http`。
  - `protocol`: 使用的协议，例如：`HTTP`、`TCP`、`HTTPS`等。
- `location`: 服务的位置。可以是`MESH_EXTERNAL`（表示服务在网格外部）或`MESH_INTERNAL`（表示服务在网格内部，但不属于任何已知服务）。
- `resolution`: 用于确定服务实例地址的解析方法。可以是`NONE`（默认值，表示不解析地址），`STATIC`（表示使用`addresses`字段中的IP地址），`DNS`（表示使用DNS解析主机名）或`MESH_EXTERNAL`。
- endpoints: （可选）外部服务的端点列表。每个端点都有以下属性：
  - `address`: 端点的IP地址或主机名。
  - `ports`: 一个包含端口名称和端口号的映射，例如：`{"http": 8080}`。
  - `labels`: （可选）应用于端点的标签。
  - `locality`: （可选）端点的地理位置，例如：`us-west1/zone1`。
- `exportTo`: （可选）一个包含命名空间名称的列表，指定可以访问此ServiceEntry的命名空间。可以使用星号（`*`）表示所有命名空间。默认值为`*`。
- `subjectAltNames`: （可选）用于验证服务器证书主题替代名（SANs）的列表