## 配置信息

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

## 示例和源码分析

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