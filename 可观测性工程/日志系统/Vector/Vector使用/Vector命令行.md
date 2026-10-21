```bash
# 生成包含组件列表的 Vector 配置
vector generate [OPTIONS] <EXPRESSION>

# 生成可视化的拓扑
vector graph [OPTIONS]

vector graph --config /etc/vector/vector.toml | dot -Tsvg > graph.svg

# 列出可用组件
vector list [FLAGS] [OPTIONS]

# 观察流入组件（转换、接收器）和流出组件（源、转换）的事件。以指定的时间间隔对事件进行采样。
vector tap [FLAGS] [OPTIONS] [ARGUMENTS]

# 配置单元测试
vector test [OPTIONS] [ARGUMENTS]

# 在控制台显示本地或远程 Vector 实例的拓扑和指标
vector top [FLAGS] [OPTIONS]

# 验证目标配置
vector validate [FLAGS] [OPTIONS] [ARGUMENTS]

# vrl CLI
vector vrl [FLAGS] [OPTIONS] [ARGUMENTS]

```

启动服务

```bash
vector -c /etc/vector/*.toml -w /etc/vector/*.toml

-c, --config <配置> 
            从一个或多个文件中读取配置。支持通配符路径
-C, --config-dir <配置目录>
-t, --threads <线程>
            用于处理的线程数（默认为可用内核数）
-w, --watch 配置
            监视配置文件的变化

```

多个配置文件，在同一个 Vector 实例中各阶段的命名也不能重名
