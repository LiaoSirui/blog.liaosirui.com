## 请求耗时分析

创建如下的一个文件：

```bash
vi curl-format.txt
```

内容：

```test
time_namelookup: %{time_namelookup}\n
time_connect: %{time_connect}\n
time_appconnect: %{time_appconnect}\n
time_redirect: %{time_redirect}\n
time_pretransfer: %{time_pretransfer}\n
time_starttransfer: %{time_starttransfer}\n
----------\n
time_total: %{time_total}\n
```

然后利用 curl 请求目标域名，就可以得到处理各个阶段的耗时情况：

```bash
curl -k -w "@curl-format.txt" -o /dev/null -s -L "https://kubernetes.default.svc.cluster.local:443"
```
