## discovery 简介

discovery 包的主要作用就是提供当前 k8s 集群支持哪些资源以及版本信息

源码地址：<https://github.com/kubernetes/client-go/tree/v12.0.0/discovery>

Kubernetes API Server 暴露出 `/api` 和 `/apis` 接口，DiscoveryClient 通过 RESTClient 分别请求 /api 和 /apis 接口，从而获取 Kubernetes API Server 所支持的资源组、资源版信息

- 这个是通过 ServerGroups 函数实现的，有了 group, version 信息后，但是还是不够，因为还没有具体到资源
- `ServerGroupsAndResources` 就获得了所有的资源信息（所有的 GVR 资源信息），而在 Resource 资源的定义中，会定义好该资源支持哪些操作：list, delelte ,get 等等

kubectl 中就使用 discovery 做了资源的校验：获取所有资源的版本信息，以及支持的操作，就可以判断客户端当前操作是否合理

## 调用 discovery 包

调用 discovery 包获取所有 gv 和 gvr 信息的代码：

```go
package main

import (
	"fmt"

	"k8s.io/apimachinery/pkg/runtime/schema"
	"k8s.io/client-go/discovery"
	"k8s.io/client-go/tools/clientcmd"
)

func main() {

	// 加载 kubeconfig 文件，生成 config 对象
	config, err := clientcmd.BuildConfigFromFlags("https://10.244.244.201:6443", "/root/.kube/config")
	if err != nil {
		panic(err)
	}

	// discovery.NewDiscoveryClientForConfig 函数
	// 通过 config 实例化 discoveryClient 对象
	discoveryClient, err := discovery.NewDiscoveryClientForConfig(config)
	if err != nil {
		panic(err)
	}

	// discoveryClient.ServerGroupsAndResources 函数
	// 返回 API Server 所支持的资源组、资源版本、资源信息
	_, APIResourceList, err := discoveryClient.ServerGroupsAndResources()
	if err != nil {
		panic(err)
	}

	// 输出所有资源信息
	for _, list := range APIResourceList {
		gv, err := schema.ParseGroupVersion(list.GroupVersion)
		if err != nil {
			panic(err)
		}

		for _, resource := range list.APIResources {
			fmt.Printf("NAME: %v, GROUP: %v, VERSION: %v \n", resource.Name, gv.Group, gv.Version)
		}
	}

}

```

执行结果

```plain
NAME: bindings, GROUP: , VERSION: v1 
NAME: componentstatuses, GROUP: , VERSION: v1 
NAME: configmaps, GROUP: , VERSION: v1 
NAME: endpoints, GROUP: , VERSION: v1 
NAME: events, GROUP: , VERSION: v1 
NAME: limitranges, GROUP: , VERSION: v1 
NAME: namespaces, GROUP: , VERSION: v1 
NAME: namespaces/finalize, GROUP: , VERSION: v1 
NAME: namespaces/status, GROUP: , VERSION: v1 
NAME: nodes, GROUP: , VERSION: v1 
NAME: nodes/proxy, GROUP: , VERSION: v1 
NAME: nodes/status, GROUP: , VERSION: v1 
NAME: persistentvolumeclaims, GROUP: , VERSION: v1 
NAME: persistentvolumeclaims/status, GROUP: , VERSION: v1 
NAME: persistentvolumes, GROUP: , VERSION: v1 
NAME: persistentvolumes/status, GROUP: , VERSION: v1 
NAME: pods, GROUP: , VERSION: v1 
NAME: pods/attach, GROUP: , VERSION: v1 
NAME: pods/binding, GROUP: , VERSION: v1 
NAME: pods/ephemeralcontainers, GROUP: , VERSION: v1 
NAME: pods/eviction, GROUP: , VERSION: v1 
NAME: pods/exec, GROUP: , VERSION: v1 
NAME: pods/log, GROUP: , VERSION: v1 
NAME: pods/portforward, GROUP: , VERSION: v1 
NAME: pods/proxy, GROUP: , VERSION: v1 
NAME: pods/status, GROUP: , VERSION: v1 
NAME: podtemplates, GROUP: , VERSION: v1 
NAME: replicationcontrollers, GROUP: , VERSION: v1 
NAME: replicationcontrollers/scale, GROUP: , VERSION: v1 
NAME: replicationcontrollers/status, GROUP: , VERSION: v1 
NAME: resourcequotas, GROUP: , VERSION: v1 
NAME: resourcequotas/status, GROUP: , VERSION: v1 
NAME: secrets, GROUP: , VERSION: v1 
NAME: serviceaccounts, GROUP: , VERSION: v1 
NAME: serviceaccounts/token, GROUP: , VERSION: v1 
NAME: services, GROUP: , VERSION: v1 
NAME: services/proxy, GROUP: , VERSION: v1 
NAME: services/status, GROUP: , VERSION: v1 
NAME: apiservices, GROUP: apiregistration.k8s.io, VERSION: v1 
NAME: apiservices/status, GROUP: apiregistration.k8s.io, VERSION: v1 
NAME: controllerrevisions, GROUP: apps, VERSION: v1 
NAME: daemonsets, GROUP: apps, VERSION: v1 
NAME: daemonsets/status, GROUP: apps, VERSION: v1 
NAME: deployments, GROUP: apps, VERSION: v1 
NAME: deployments/scale, GROUP: apps, VERSION: v1 
NAME: deployments/status, GROUP: apps, VERSION: v1 
NAME: replicasets, GROUP: apps, VERSION: v1 
NAME: replicasets/scale, GROUP: apps, VERSION: v1 
NAME: replicasets/status, GROUP: apps, VERSION: v1 
NAME: statefulsets, GROUP: apps, VERSION: v1 
NAME: statefulsets/scale, GROUP: apps, VERSION: v1 
NAME: statefulsets/status, GROUP: apps, VERSION: v1 
NAME: events, GROUP: events.k8s.io, VERSION: v1 
...
```

`kubectl api-resources` 和 `kubectl api-versions` 这两条命令也是调用的该 discover 包

```bash
> kubectl --help |grep api-

  api-resources   Print the supported API resources on the server
  api-versions    Print the supported API versions on the server, in the form of "group/version"
```

上面的 main 方法，分为 4 步：

（1）`clientcmd.BuildConfigFromFlags` 函数返回 config 对象，这里用了 kubeconfig 的本地路径

（2）`discovery.NewDiscoveryClientForConfig` 函数返回 DiscoveryClient 对象

Refer: <https://github.com/kubernetes/client-go/blob/v0.26.1/discovery/discovery_client.go#L654-L680>

```go
// NewDiscoveryClientForConfig creates a new DiscoveryClient for the given config. This client
// can be used to discover supported resources in the API server.
// NewDiscoveryClientForConfig is equivalent to NewDiscoveryClientForConfigAndClient(c, httpClient),
// where httpClient was generated with rest.HTTPClientFor(c).
func NewDiscoveryClientForConfig(c *restclient.Config) (*DiscoveryClient, error) {
	config := *c
	if err := setDiscoveryDefaults(&config); err != nil {
		return nil, err
	}
	httpClient, err := restclient.HTTPClientFor(&config)
	if err != nil {
		return nil, err
	}
	return NewDiscoveryClientForConfigAndClient(&config, httpClient)
}

// NewDiscoveryClientForConfigAndClient creates a new DiscoveryClient for the given config. This client
// can be used to discover supported resources in the API server.
// Note the http client provided takes precedence over the configured transport values.
func NewDiscoveryClientForConfigAndClient(c *restclient.Config, httpClient *http.Client) (*DiscoveryClient, error) {
	config := *c
	if err := setDiscoveryDefaults(&config); err != nil {
		return nil, err
	}
	client, err := restclient.UnversionedRESTClientForConfigAndClient(&config, httpClient)
	return &DiscoveryClient{restClient: client, LegacyPrefix: "/api", UseLegacyDiscovery: false}, err
}

```

