HashiCorp Vault 的 CSI (Container Storage Interface) Provider 和 Sidecar Injector 

都是将 Vault Secrets 注入 Kubernetes Pod 的方法，但工作方式不同：CSI Provider 使用 Kubernetes Secret Store CSI Driver 将 secrets 挂载为 Pod 文件系统中的临时卷，更接近 Kubernetes 原生；而 Sidecar Injector 注入一个 Sidecar 容器（Vault Agent），动态管理 secrets，支持自动续期、轮换，并将它们作为环境变量或文件注入，功能更强大，但配置略复杂，CSI 适合简单的挂载，Sidecar 适合需要动态更新的场景

