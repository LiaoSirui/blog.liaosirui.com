## NetworkPolicy 配置详解

说明：除非选择支持网络策略的网络解决方案，否则将发送到 API 服务器没有任何效果

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: test-network-policy
  namespace: default
spec:
  podSelector:
    matchLabels:
      role: db
  policyTypes:
  - Ingress
  - Egress
  ingress:
  - from:
    - ipBlock:
        cidr: 172.17.0.0/16
        except:
        - 172.17.1.0/24
    - namespaceSelector:
        matchLabels:
          project: myproject
    - podSelector:
        matchLabels:
          role: frontend
    ports:
    - protocol: TCP
      port: 6379
  egress:
  - to:
    - ipBlock:
        cidr: 10.0.0.0/24
    ports:
    - protocol: TCP
      port: 5978

```

- 必需字段：与所有其他的 Kubernetes 配置一样，NetworkPolicy 需要 apiVersion、 kind 和 metadata 字段

- spec：NetworkPolicy 规约 中包含了在一个名字空间中定义特定网络策略所需的所有信息。

  - podSelector：每个 NetworkPolicy 都包括一个 podSelector，它对该策略所 适用的一组 Pod 进行选择。示例中的策略选择带有 "role=db" 标签的 Pod。空的 podSelector 选择名字空间下的所有 Pod。

  - policyTypes: 每个 NetworkPolicy 都包含一个 policyTypes 列表，其中包含 Ingress 或 Egress 或两者兼具。policyTypes 字段表示给定的策略是应用于 进入所选 Pod 的入站流量还是来自所选 Pod 的出站流量，或两者兼有。如果 NetworkPolicy 未指定 policyTypes 则默认情况下始终设置 Ingress；如果 NetworkPolicy 有任何出口规则的话则设置 Egress。

  - ingress: 每个 NetworkPolicy 可包含一个 ingress 规则的白名单列表

    每个规则都允许同时匹配 from 和 ports 部分的流量。示例策略中包含一条简单的规则：它匹配某个特定端口，来自三个来源中的一个，第一个通过 ipBlock 指定，第二个通过 namespaceSelector 指定，第三个通过 podSelector 指定。

  - egress: 每个 NetworkPolicy 可包含一个 egress 规则的白名单列表

    每个规则都允许匹配 to 和 port 部分的流量。该示例策略包含一条规则，该规则将指定端口上的流量匹配到 10.0.0.0/24 中的任何目的地。

所以，该网络策略示例:

1. 隔离 "default" 名字空间下 "role=db" 的 Pod （如果它们不是已经被隔离的话）

2. （Ingress 规则）允许以下 Pod 连接到 "default" 名字空间下的带有 "role=db" 标签的所有 Pod 的 6379 TCP 端口：

3. - "default" 名字空间下带有 "role=frontend" 标签的所有 Pod
   - 带有 "project=myproject" 标签的所有名字空间中的 Pod
   - IP 地址范围为 172.17.0.0–172.17.0.255 和 172.17.2.0–172.17.255.255 （即，除了 172.17.1.0/24 之外的所有 172.17.0.0/16）

4. （Egress 规则）允许从带有 "role=db" 标签的名字空间下的任何 Pod 到 CIDR 10.0.0.0/24 下 5978 TCP 端口的连接

在配置网络策略时，有很多细节需要注意，比如上述的示例中，一段关于 ingress 的 from 配置：

```yaml
 - from:
    - ipBlock:
        cidr: 172.17.0.0/16
        except:
        - 172.17.1.0/24
    - namespaceSelector:
        matchLabels:
          project: myproject
    - podSelector:
        matchLabels:
          role: frontend
# namespaceSelector 和 podSelector 是或的关系，表示两个条件满足一个就可以

```

需要注意的是在 ipBlock、namespaceSelector 和 podSelector 前面都有一个 `-`，如果前面没有这个横杠将是另外一个完全不同的概念

可以看一下下面的示例：

```yaml
- from:
    - ipBlock:
        cidr: 172.17.0.0/16
        except:
        - 172.17.1.0/24
    - namespaceSelector:
        matchLabels:
          project: myproject
      podSelector:
        matchLabels:
          role: frontend
# namespaceSelector 和 podSelector 是并且的关系，表示两个条件都满足
```

此时的 namespaceSelector 有 “-”，podSelector 没有 “-”，那此时的配置，代表的含义是允许具有 `user=Alice` 标签的 Namespace 下，并且具有 `role=client` 标签的所有 Pod 访问，namespaceSelector 和 podSelector 是且的关系

```yaml
ingress:
  - from:
    - namespaceSelector:
        matchLabels:
          user: alice
    - podSelector:
        matchLabels:
          role: client
```

此时的 namespaceSelector 和 podSelector 都有“-”，配置的含义是允许具有 `user=Alice` 标签 的Namespace 下的所有 Pod 和当前 Namespace 下具有 `role=client` 标签的 Pod 访问，namespaceSelector 和 podSelector 是或的关系

在配置 ipBlock 时，可能也会出现差异性

因为在接收或者发送流量时，很有可能伴随着数据包中源 IP 和目标 IP 的重写，也就是 SNAT 和  DNAT，此时会造成流量的目标 IP 和源 IP 与配置的 ipBlock 出现了差异性，造成网络策略不生效，所以在配置 IPBlock 时，需要确认网络交换中是否存在源目地址转换

并且 IPBlock 最好不要配置 Pod的 IP，因为 Pod 发生重建时，它的 IP 地址一般就会发生变更，所以 IPBlock 一般用于配置集群的外部 IP