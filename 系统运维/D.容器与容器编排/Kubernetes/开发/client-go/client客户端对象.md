## Client 客户端对象

client-go 的客户端对象有四个，关系如下：

![img](.assets/client.svg)

四种客户端都可以通过 kubeconfig 配置信息连接到指定到 Kubernetes API Server

作用各有不同：

- RESTClient

是对 HTTP Request 进行了封装，实现了 RESTful 风格的 API

RESTClient 是最基础的客户端，ClientSet、DynamicClient 及 DiscoveryClient 客户端都是在 RESTClient 基础上的实现，可与用于 k8s 内置资源和 CRD 资源

- ClientSet

ClientSet 在 RESTClient 的基础上封装了对 Resource 和 Version 的管理方案，是对 k8s 内置资源对象的客户端的集合

每一个 Resource 可以理解为一个客户端，而 ClientSet 则是多个客户端的集合，每一个 Resource 和 Version 都以函数的方式暴露给开发者；ClientSet 只能够处理 Kubernetes 内置资源，它是通过 client-gen 代码生成器自动生成的

默认情况下，不能操作 CRD 资源，但是通过 client-gen 代码生成的话，也是可以操作 CRD 资源的

- DynamicClient

DynamicClient 与 ClientSet 最大的不同之处是，ClientSet 仅能访问 Kubernetes 自带的资源 (即 Client 集合内的资源)，不能直接访问 CRD 自定义资源

DynamicClient 能够处理 Kubernetes 中的所有资源对象，包括 Kubernetes 内置资源与 CRD 自定义资源，不需要 client-gen 生成代码即可实现

- DiscoveryClient

DiscoveryClient 发现客户端，用于发现 kube-apiserver 所支持的资源组、资源版本、资源信息 (即 Group、Version、Resources)

## kubeconfig 配置管理

### 配置信息

kubeconfig 可用于管理访问 kube-apiserver 的配置信息，也支持多集群的配置管理，可在不同环境下管理不同 kube-apiserver 集群配置。kubernetes 的其他组件都是用 kubeconfig 配置信息来连接 kube-apiserver 组件。

kubeconfig 存储了集群、用户、命名空间和身份验证等信息，默认 kubeconfig 存放在 `$HOME/.kube/config` 路径下

kubeconfig 的配置信息如下：

```yaml
---
apiVersion: v1
kind: Config
clusters:
  - name: kubernetes
    cluster:
      certificate-authority-data: LS0tLS1CRU...
      server: https://apiserver.local.liaosirui.com:6443
users:
  - name: kubernetes-admin
    user:
      client-certificate-data: LS0tLS1CRUd...
      client-key-data: LS0tLS1CR...
contexts:
  - name: kubernetes-admin@kubernetes
    context:
      cluster: kubernetes
      namespace: dev-container
      user: kubernetes-admin
current-context: kubernetes-admin@kubernetes
preferences: {}

```

kubeconfig 配置信息分为 3 部分，分别为：

- clusters

定义 kubernetes 集群信息，例如 kube-apiserver 的服务地址及集群的证书信息

- users

定义 kubernetes 集群用户身份验证的客户端凭据，例如 client-certificate、client-key、token 及 username/password 等

- context

定义 kuberntes 集群用户信息和命名空间等，用于将请求发送到指定的集群

### 示例和源码分析

加载 kubeconfig 并查询 Pod 信息，代码如下：

```go
package main

import (
	"context"
	"fmt"

	metaV1 "k8s.io/apimachinery/pkg/apis/meta/v1"
	"k8s.io/client-go/kubernetes"
	"k8s.io/client-go/tools/clientcmd"
)

func main() {

	// 加载 kubeconfig 文件，生成 config 对象
	config, err := clientcmd.BuildConfigFromFlags("https://10.244.244.201:6443", "/root/.kube/config")
	if err != nil {
		panic(err)
	}

	// 通过 config 对象得到 ClientSet 客户端对象
	clientSet, err := kubernetes.NewForConfig(config)
	if err != nil {
		panic(err)
	}

	// 使用 ClientSet 客户端对象通过资源函数进行 Pod 资源的访问
	pod, err := clientSet.CoreV1().
		Pods("dev-container").
		Get(context.Background(), "dev-container-0", metaV1.GetOptions{})
	if err != nil {
		panic(err)
	}

	// 打印 pod 的状态信息
	fmt.Println(pod.Status.String())

}

```

加载 kubeconfig 配置信息

源码：<https://github.com/kubernetes/client-go/blob/v0.26.1/tools/clientcmd/client_config.go#L611-L628>

```go
// BuildConfigFromFlags is a helper function that builds configs from a master
// url or a kubeconfig filepath. These are passed in as command line flags for cluster
// components. Warnings should reflect this usage. If neither masterUrl or kubeconfigPath
// are passed in we fallback to inClusterConfig. If inClusterConfig fails, we fallback
// to the default config.
func BuildConfigFromFlags(masterUrl, kubeconfigPath string) (*restclient.Config, error) {
	if kubeconfigPath == "" && masterUrl == "" {
		klog.Warning("Neither --kubeconfig nor --master was specified.  Using the inClusterConfig.  This might not work.")
		kubeconfig, err := restclient.InClusterConfig()
		if err == nil {
			return kubeconfig, nil
		}
		klog.Warning("error creating inClusterConfig, falling back to default config: ", err)
	}
	return NewNonInteractiveDeferredLoadingClientConfig(
		&ClientConfigLoadingRules{ExplicitPath: kubeconfigPath},
		&ConfigOverrides{ClusterInfo: clientcmdapi.Cluster{Server: masterUrl}}).ClientConfig()
}

```

在示例的调用中，传入了参数，因此调用 `ClientConfig.ClientConfig()`

源码：<>

```go
// ClientConfig implements ClientConfig
func (config *DirectClientConfig) ClientConfig() (*restclient.Config, error) {
	// check that getAuthInfo, getContext, and getCluster do not return an error.
	// Do this before checking if the current config is usable in the event that an
	// AuthInfo, Context, or Cluster config with user-defined names are not found.
	// This provides a user with the immediate cause for error if one is found
	configAuthInfo, err := config.getAuthInfo()
	if err != nil {
		return nil, err
	}

	_, err = config.getContext()
	if err != nil {
		return nil, err
	}

	configClusterInfo, err := config.getCluster()
	if err != nil {
		return nil, err
	}

	if err := config.ConfirmUsable(); err != nil {
		return nil, err
	}

	clientConfig := &restclient.Config{}
	clientConfig.Host = configClusterInfo.Server
	if configClusterInfo.ProxyURL != "" {
		u, err := parseProxyURL(configClusterInfo.ProxyURL)
		if err != nil {
			return nil, err
		}
		clientConfig.Proxy = http.ProxyURL(u)
	}

	clientConfig.DisableCompression = configClusterInfo.DisableCompression

	if config.overrides != nil && len(config.overrides.Timeout) > 0 {
		timeout, err := ParseTimeout(config.overrides.Timeout)
		if err != nil {
			return nil, err
		}
		clientConfig.Timeout = timeout
	}

	if u, err := url.ParseRequestURI(clientConfig.Host); err == nil && u.Opaque == "" && len(u.Path) > 1 {
		u.RawQuery = ""
		u.Fragment = ""
		clientConfig.Host = u.String()
	}
	if len(configAuthInfo.Impersonate) > 0 {
		clientConfig.Impersonate = restclient.ImpersonationConfig{
			UserName: configAuthInfo.Impersonate,
			UID:      configAuthInfo.ImpersonateUID,
			Groups:   configAuthInfo.ImpersonateGroups,
			Extra:    configAuthInfo.ImpersonateUserExtra,
		}
	}

	// only try to read the auth information if we are secure
	if restclient.IsConfigTransportTLS(*clientConfig) {
		var err error
		var persister restclient.AuthProviderConfigPersister
		if config.configAccess != nil {
			authInfoName, _ := config.getAuthInfoName()
			persister = PersisterForUser(config.configAccess, authInfoName)
		}
		userAuthPartialConfig, err := config.getUserIdentificationPartialConfig(configAuthInfo, config.fallbackReader, persister, configClusterInfo)
		if err != nil {
			return nil, err
		}
		mergo.Merge(clientConfig, userAuthPartialConfig, mergo.WithOverride)

		serverAuthPartialConfig, err := getServerIdentificationPartialConfig(configAuthInfo, configClusterInfo)
		if err != nil {
			return nil, err
		}
		mergo.Merge(clientConfig, serverAuthPartialConfig, mergo.WithOverride)
	}

	return clientConfig, nil
}

```

源码：<https://github.com/kubernetes/client-go/blob/v0.26.1/tools/clientcmd/loader.go#L160-L252>

```go

```

<https://herbguo.gitbook.io/client-go/client_obj>

## ClientSet

## DynamicClient

## DiscoveryClient

### discovery 简介

discovery 包的主要作用就是提供当前 k8s 集群支持哪些资源以及版本信息

源码地址：<https://github.com/kubernetes/client-go/tree/v12.0.0/discovery>

Kubernetes API Server 暴露出 `/api` 和 `/apis` 接口，DiscoveryClient 通过 RESTClient 分别请求 /api 和 /apis 接口，从而获取 Kubernetes API Server 所支持的资源组、资源版信息

- 这个是通过 ServerGroups 函数实现的，有了 group, version 信息后，但是还是不够，因为还没有具体到资源
- `ServerGroupsAndResources` 就获得了所有的资源信息（所有的 GVR 资源信息），而在 Resource 资源的定义中，会定义好该资源支持哪些操作：list, delelte ,get 等等

kubectl 中就使用 discovery 做了资源的校验：获取所有资源的版本信息，以及支持的操作，就可以判断客户端当前操作是否合理

### 调用 discovery 包

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

### 参考资料

<https://www.cnblogs.com/bolingcavalry/p/15236581.html>
