## 简介

不管是 sealos 还是 sealctl 命令行，都离不开 buildah

<https://github.com/labring/sealos/blob/v5.1.1/lifecycle/cmd/sealos/main.go#L15-L28>

```go
package main

import (
	"github.com/containers/buildah"

	"github.com/labring/sealos/cmd/sealos/cmd"
)

func main() {
	if buildah.InitReexec() {
		return
	}
	cmd.Execute()
}

```

从 `InitReexec` 调用 buildah 初始化开始

接着是 `cmd.Execute()`

在调用的时候，会先执行 `init` 初始化函数，它定义了一些初始化工作以及标志：

<https://github.com/labring/sealos/blob/v5.1.1/lifecycle/cmd/sealos/cmd/root.go#L57-L104>

```go
func init() {
	cobra.OnInitialize(onBootOnDie)
	rootCmd.PersistentFlags().BoolVar(&debug, "debug", false, "enable debug logger")
	buildah.RegisterRootCommand(rootCmd)

	groups := templates.CommandGroups{
		// ...
	}
	groups.Add(rootCmd)
	filters := []string{"options"}
	templates.ActsAsRootCommand(rootCmd, filters, groups...)

	rootCmd.AddCommand(system.NewEnvCmd(constants.AppName))
	rootCmd.AddCommand(optionsCommand(os.Stdout))
}
```

## Run 命令

### Run 命令入口

run 的时候 cmd 将执行

<https://github.com/labring/sealos/blob/v5.1.1/lifecycle/cmd/sealos/cmd/run.go#L73>

```go
applier, err := apply.NewApplierFromArgs(cmd, runArgs, images)
```

`NewApplierFromArgs` 用于创建一个 `Applier` 实例对象

它接收两个参数：一个是镜像名称数组 `imageName`，另一个是运行参数 args

在这个函数中，它实现了从参数中获取 `ClusterName`，然后根据 `ClusterName` 获取对应的 `ClusterFile`，如果获取不到，则创建一个新的。接着，它根据用户输入的参数，更新集群状态 Cluster 中的 spec，最后通过 Cluster 对象和 ClusterFile 对象，创建一个 Applier 对象返回

<https://github.com/labring/sealos/blob/v5.1.1/lifecycle/pkg/apply/run.go#L46-L79>

```go
func NewApplierFromArgs(cmd *cobra.Command, args *RunArgs, imageName []string) (applydrivers.Interface, error) {
	clusterPath := constants.Clusterfile(args.ClusterName)
	cf := clusterfile.NewClusterFile(clusterPath,
		clusterfile.WithCustomConfigFiles(args.CustomConfigFiles),
		clusterfile.WithCustomEnvs(args.CustomEnv),
	)
	err := cf.Process()
	if err != nil && err != clusterfile.ErrClusterFileNotExists {
		return nil, err
	}

	cluster := cf.GetCluster()
	if cluster == nil {
		logger.Debug("creating new cluster")
		if args.Masters == "" && args.Nodes == "" {
			addr, _ := iputils.ListLocalHostAddrs()
			args.Masters = iputils.LocalIP(addr)
		}
		cluster = initCluster(args.ClusterName)
	} else {
		cluster = cluster.DeepCopy()
	}
	c := &ClusterArgs{
		clusterName: cluster.Name,
		cluster:     cluster,
	}
	if err = c.runArgs(cmd, args, imageName); err != nil {
		return nil, err
	}

	ctx := withCommonContext(cmd.Context(), cmd)

	return applydrivers.NewDefaultApplier(ctx, c.cluster, cf, imageName)
}
```

### Applier

Sealos 会创建一个 Applier 结构体，负责部署集群的核心逻辑。



