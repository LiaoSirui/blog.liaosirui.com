## 连接 k8s 的 etcd

需要在命令前加上 `ETCDCTL_API=3` 这个环境变量才能看到 kuberentes 在 etcd 中保存的数据。

如果是使用 kubeadm 创建的集群，etcd 默认使用 tls。

可以使用如下的脚本进行 alias

```bash
export TEMP_ETCDCTL_ENDPOINTS=https://10.244.244.201:2379

export ETCDCTL_API=3
export ETCDCTL_CACERT=/etc/kubernetes/pki/etcd/ca.crt
export ETCDCTL_CERT=/etc/kubernetes/pki/etcd/server.crt
export ETCDCTL_KEY=/etc/kubernetes/pki/etcd/server.key

export ETCDCTL_DIAL_TIMEOUT=3s

alias netcdctl='etcdctl --endpoints=${TEMP_ETCDCTL_ENDPOINTS}'
```

本文使用的环境为单节点，如果是多节点，可以使用如下的方式：

```bash
export HOST_1=https://192.168.148.115
export HOST_2=https://192.168.148.116
export HOST_3=https://192.168.148.117
export TEMP_ETCDCTL_ENDPOINTS=$HOST_1:2379,$HOST_2:2379,$HOST_3:2379

export ETCDCTL_API=3
export ETCDCTL_CACERT=/etc/kubernetes/pki/etcd/ca.crt
export ETCDCTL_CERT=/etc/kubernetes/pki/etcd/server.crt
export ETCDCTL_KEY=/etc/kubernetes/pki/etcd/server.key

export ETCDCTL_DIAL_TIMEOUT=3s

alias netcdctl='etcdctl --endpoints=${TEMP_ETCDCTL_ENDPOINTS}'
```

尝试获取数据

```bash
etcdctl get /registry/namespaces/default -w=json | jq .
```

将得到这样的 json 的结果：

```json
{
  "header": {
    "cluster_id": 12855637903679668459,
    "member_id": 6127129462884297024,
    "revision": 3632815,
    "raft_term": 19
  },
  "kvs": [
    {
      "key": "L3JlZ2lzdHJ5L25hbWVzcGFjZXMvZGVmYXVsdA==",
      "create_revision": 191,
      "mod_revision": 191,
      "version": 1,
      "value": "azhzAAoPCgJ2MRIJTmFtZXNwYWNlEoYCCusBCgdkZWZhdWx0EgAaACIAKiRjODM0MjJjOC03YjcxLTQ2NDgtYmM4Ni1hYzU0YWU4ZmIxODgyADgAQggI4f3CngYQAFomChtrdWJlcm5ldGVzLmlvL21ldGFkYXRhLm5hbWUSB2RlZmF1bHSKAX0KDmt1YmUtYXBpc2VydmVyEgZVcGRhdGUaAnYxIggI4f3CngYQADIIRmllbGRzVjE6SQpHeyJmOm1ldGFkYXRhIjp7ImY6bGFiZWxzIjp7Ii4iOnt9LCJmOmt1YmVybmV0ZXMuaW8vbWV0YWRhdGEubmFtZSI6e319fX1CABIMCgprdWJlcm5ldGVzGggKBkFjdGl2ZRoAIgA="
    }
  ],
  "count": 1
}
```

使用 `--prefix` 可以看到所有的子目录，如查看集群中的 namespace：

```bash
etcdctl get /registry/namespaces --prefix -w=json | jq .
```

输出结果中可以看到所有的 namespace。

````bash
{
  "header": {
    "cluster_id": 12855637903679668459,
    "member_id": 6127129462884297024,
    "revision": 3632996,
    "raft_term": 19
  },
  "kvs": [
    {
      "key": "L3JlZ2lzdHJ5L25hbWVzcGFjZXMvYWlwYWFzLXN5c3RlbQ==",
      "create_revision": 1446560,
      "mod_revision": 1446560,
      "version": 1,
      "value": "azhzAAoPCgJ2MRIJTmFtZXNwYWNlEqsCCpACCg1haXBhYXMtc3lzdGVtEgAaACIAKiRlMzM1ZjM2Ni1hYmQxLTQyNTMtODUwMy1kNTc0NWRmMGU5NmEyADgAQggI4MfsngYQAFosChtrdWJlcm5ldGVzLmlvL21ldGFkYXRhLm5hbWUSDWFpcGFhcy1zeXN0ZW1aFQoEbmFtZRINYWlwYWFzLXN5c3RlbYoBfwoEaGVsbRIGVXBkYXRlGgJ2MSIICODH7J4GEAAyCEZpZWxkc1YxOlUKU3siZjptZXRhZGF0YSI6eyJmOmxhYmVscyI6eyIuIjp7fSwiZjprdWJlcm5ldGVzLmlvL21ldGFkYXRhLm5hbWUiOnt9LCJmOm5hbWUiOnt9fX19QgASDAoKa3ViZXJuZXRlcxoICgZBY3RpdmUaACIA"
    },
    {
      "key": "L3JlZ2lzdHJ5L25hbWVzcGFjZXMvYmVlZ2ZzLWNzaQ==",
      "create_revision": 1356095,
      "mod_revision": 1356095,
      "version": 1,
      "value": "azhzAAoPCgJ2MRIJTmFtZXNwYWNlEvsDCuADCgpiZWVnZnMtY3NpEgAaACIAKiQ0YTQ1NzBmYi03MTg1LTQ3MjYtYmQ4My04NmUxYzQ2Njg4OWUyADgAQggI4oDqngYQAFopChtrdWJlcm5ldGVzLmlvL21ldGFkYXRhLm5hbWUSCmJlZWdmcy1jc2lijQEKMGt1YmVjdGwua3ViZXJuZXRlcy5pby9sYXN0LWFwcGxpZWQtY29uZmlndXJhdGlvbhJZeyJhcGlWZXJzaW9uIjoidjEiLCJraW5kIjoiTmFtZXNwYWNlIiwibWV0YWRhdGEiOnsiYW5ub3RhdGlvbnMiOnt9LCJuYW1lIjoiYmVlZ2ZzLWNzaSJ9fQqKAdsBChlrdWJlY3RsLWNsaWVudC1zaWRlLWFwcGx5EgZVcGRhdGUaAnYxIggI4oDqngYQADIIRmllbGRzVjE6mwEKmAF7ImY6bWV0YWRhdGEiOnsiZjphbm5vdGF0aW9ucyI6eyIuIjp7fSwiZjprdWJlY3RsLmt1YmVybmV0ZXMuaW8vbGFzdC1hcHBsaWVkLWNvbmZpZ3VyYXRpb24iOnt9fSwiZjpsYWJlbHMiOnsiLiI6e30sImY6a3ViZXJuZXRlcy5pby9tZXRhZGF0YS5uYW1lIjp7fX19fUIAEgwKCmt1YmVybmV0ZXMaCAoGQWN0aXZlGgAiAA=="
    },
    {
      "key": "L3JlZ2lzdHJ5L25hbWVzcGFjZXMvY2VydC1tYW5hZ2Vy",
      "create_revision": 2836544,
      "mod_revision": 2836544,
      "version": 1,
      "value": "azhzAAoPCgJ2MRIJTmFtZXNwYWNlEqgCCo0CCgxjZXJ0LW1hbmFnZXISABoAIgAqJDdjMjdjYTY5LWU4OWYtNGNkMy1iMTgzLTQ3MTg0NTc2OWE0NTIAOABCCAi8uJGfBhAAWisKG2t1YmVybmV0ZXMuaW8vbWV0YWRhdGEubmFtZRIMY2VydC1tYW5hZ2VyWhQKBG5hbWUSDGNlcnQtbWFuYWdlcooBfwoEaGVsbRIGVXBkYXRlGgJ2MSIICLy4kZ8GEAAyCEZpZWxkc1YxOlUKU3siZjptZXRhZGF0YSI6eyJmOmxhYmVscyI6eyIuIjp7fSwiZjprdWJlcm5ldGVzLmlvL21ldGFkYXRhLm5hbWUiOnt9LCJmOm5hbWUiOnt9fX19QgASDAoKa3ViZXJuZXRlcxoICgZBY3RpdmUaACIA"
    },
    {
      "key": "L3JlZ2lzdHJ5L25hbWVzcGFjZXMvZGVmYXVsdA==",
      "create_revision": 191,
      "mod_revision": 191,
      "version": 1,
      "value": "azhzAAoPCgJ2MRIJTmFtZXNwYWNlEoYCCusBCgdkZWZhdWx0EgAaACIAKiRjODM0MjJjOC03YjcxLTQ2NDgtYmM4Ni1hYzU0YWU4ZmIxODgyADgAQggI4f3CngYQAFomChtrdWJlcm5ldGVzLmlvL21ldGFkYXRhLm5hbWUSB2RlZmF1bHSKAX0KDmt1YmUtYXBpc2VydmVyEgZVcGRhdGUaAnYxIggI4f3CngYQADIIRmllbGRzVjE6SQpHeyJmOm1ldGFkYXRhIjp7ImY6bGFiZWxzIjp7Ii4iOnt9LCJmOmt1YmVybmV0ZXMuaW8vbWV0YWRhdGEubmFtZSI6e319fX1CABIMCgprdWJlcm5ldGVzGggKBkFjdGl2ZRoAIgA="
    },
    {
      "key": "L3JlZ2lzdHJ5L25hbWVzcGFjZXMvaW5ncmVzcy1uZ2lueA==",
      "create_revision": 5416,
      "mod_revision": 5416,
      "version": 1,
      "value": "azhzAAoPCgJ2MRIJTmFtZXNwYWNlEqsCCpACCg1pbmdyZXNzLW5naW54EgAaACIAKiQ5ZTlkZjIyOC00MTEyLTRiMWUtYjU5OS04ZTJmZTk2ODQ1NDQyADgAQggI5ZLDngYQAFosChtrdWJlcm5ldGVzLmlvL21ldGFkYXRhLm5hbWUSDWluZ3Jlc3MtbmdpbnhaFQoEbmFtZRINaW5ncmVzcy1uZ2lueIoBfwoEaGVsbRIGVXBkYXRlGgJ2MSIICOWSw54GEAAyCEZpZWxkc1YxOlUKU3siZjptZXRhZGF0YSI6eyJmOmxhYmVscyI6eyIuIjp7fSwiZjprdWJlcm5ldGVzLmlvL21ldGFkYXRhLm5hbWUiOnt9LCJmOm5hbWUiOnt9fX19QgASDAoKa3ViZXJuZXRlcxoICgZBY3RpdmUaACIA"
    },
    {
      "key": "L3JlZ2lzdHJ5L25hbWVzcGFjZXMva3ViZS1ub2RlLWxlYXNl",
      "create_revision": 8,
      "mod_revision": 8,
      "version": 1,
      "value": "azhzAAoPCgJ2MRIJTmFtZXNwYWNlEpYCCvsBCg9rdWJlLW5vZGUtbGVhc2USABoAIgAqJDUxZTk4NTY0LWFmYWQtNDZmMC05YWVjLWU3ZmFkYWMxY2M4ZDIAOABCCAjg/cKeBhAAWi4KG2t1YmVybmV0ZXMuaW8vbWV0YWRhdGEubmFtZRIPa3ViZS1ub2RlLWxlYXNligF9Cg5rdWJlLWFwaXNlcnZlchIGVXBkYXRlGgJ2MSIICOD9wp4GEAAyCEZpZWxkc1YxOkkKR3siZjptZXRhZGF0YSI6eyJmOmxhYmVscyI6eyIuIjp7fSwiZjprdWJlcm5ldGVzLmlvL21ldGFkYXRhLm5hbWUiOnt9fX19QgASDAoKa3ViZXJuZXRlcxoICgZBY3RpdmUaACIA"
    },
    {
      "key": "L3JlZ2lzdHJ5L25hbWVzcGFjZXMva3ViZS1wdWJsaWM=",
      "create_revision": 7,
      "mod_revision": 7,
      "version": 1,
      "value": "azhzAAoPCgJ2MRIJTmFtZXNwYWNlEo4CCvMBCgtrdWJlLXB1YmxpYxIAGgAiACokYTMwMDBiMDctYmI5My00OTIzLTgzMTAtNWRmMjZhMGMwNTdhMgA4AEIICOD9wp4GEABaKgoba3ViZXJuZXRlcy5pby9tZXRhZGF0YS5uYW1lEgtrdWJlLXB1YmxpY4oBfQoOa3ViZS1hcGlzZXJ2ZXISBlVwZGF0ZRoCdjEiCAjg/cKeBhAAMghGaWVsZHNWMTpJCkd7ImY6bWV0YWRhdGEiOnsiZjpsYWJlbHMiOnsiLiI6e30sImY6a3ViZXJuZXRlcy5pby9tZXRhZGF0YS5uYW1lIjp7fX19fUIAEgwKCmt1YmVybmV0ZXMaCAoGQWN0aXZlGgAiAA=="
    },
    {
      "key": "L3JlZ2lzdHJ5L25hbWVzcGFjZXMva3ViZS1zeXN0ZW0=",
      "create_revision": 5,
      "mod_revision": 5,
      "version": 1,
      "value": "azhzAAoPCgJ2MRIJTmFtZXNwYWNlEo4CCvMBCgtrdWJlLXN5c3RlbRIAGgAiACokNDJlZjAxMDQtOWY1MS00YTk1LWJkZDItMmRmY2FjYTAyZWVjMgA4AEIICOD9wp4GEABaKgoba3ViZXJuZXRlcy5pby9tZXRhZGF0YS5uYW1lEgtrdWJlLXN5c3RlbYoBfQoOa3ViZS1hcGlzZXJ2ZXISBlVwZGF0ZRoCdjEiCAjg/cKeBhAAMghGaWVsZHNWMTpJCkd7ImY6bWV0YWRhdGEiOnsiZjpsYWJlbHMiOnsiLiI6e30sImY6a3ViZXJuZXRlcy5pby9tZXRhZGF0YS5uYW1lIjp7fX19fUIAEgwKCmt1YmVybmV0ZXMaCAoGQWN0aXZlGgAiAA=="
    },
    {
      "key": "L3JlZ2lzdHJ5L25hbWVzcGFjZXMva3ViZXJuZXRlcy1kYXNoYm9hcmQ=",
      "create_revision": 2845067,
      "mod_revision": 2845067,
      "version": 1,
      "value": "azhzAAoPCgJ2MRIJTmFtZXNwYWNlEsACCqUCChRrdWJlcm5ldGVzLWRhc2hib2FyZBIAGgAiACokMmRhNzhjZDItZjRjYy00YjNmLWJmYWQtNDQwYTEzNTg1MTMzMgA4AEIICKLRkZ8GEABaMwoba3ViZXJuZXRlcy5pby9tZXRhZGF0YS5uYW1lEhRrdWJlcm5ldGVzLWRhc2hib2FyZFocCgRuYW1lEhRrdWJlcm5ldGVzLWRhc2hib2FyZIoBfwoEaGVsbRIGVXBkYXRlGgJ2MSIICKLRkZ8GEAAyCEZpZWxkc1YxOlUKU3siZjptZXRhZGF0YSI6eyJmOmxhYmVscyI6eyIuIjp7fSwiZjprdWJlcm5ldGVzLmlvL21ldGFkYXRhLm5hbWUiOnt9LCJmOm5hbWUiOnt9fX19QgASDAoKa3ViZXJuZXRlcxoICgZBY3RpdmUaACIA"
    },
    {
      "key": "L3JlZ2lzdHJ5L25hbWVzcGFjZXMvbG9jYWwtYXBwcw==",
      "create_revision": 2643912,
      "mod_revision": 2643912,
      "version": 1,
      "value": "azhzAAoPCgJ2MRIJTmFtZXNwYWNlEowCCvEBCgpsb2NhbC1hcHBzEgAaACIAKiQwYzAzNzI1ZC00ZDc2LTQ3NWYtODkwYS1jNmRhZTA1NWM0YjQyADgAQggIm9eMnwYQAFopChtrdWJlcm5ldGVzLmlvL21ldGFkYXRhLm5hbWUSCmxvY2FsLWFwcHOKAX0KDmt1YmVjdGwtY3JlYXRlEgZVcGRhdGUaAnYxIggIm9eMnwYQADIIRmllbGRzVjE6SQpHeyJmOm1ldGFkYXRhIjp7ImY6bGFiZWxzIjp7Ii4iOnt9LCJmOmt1YmVybmV0ZXMuaW8vbWV0YWRhdGEubmFtZSI6e319fX1CABIMCgprdWJlcm5ldGVzGggKBkFjdGl2ZRoAIgA="
    },
    {
      "key": "L3JlZ2lzdHJ5L25hbWVzcGFjZXMvbWV0YWxsYi1zeXN0ZW0=",
      "create_revision": 2460022,
      "mod_revision": 2460022,
      "version": 1,
      "value": "azhzAAoPCgJ2MRIJTmFtZXNwYWNlEq4CCpMCCg5tZXRhbGxiLXN5c3RlbRIAGgAiACokZTE2YzViODYtYjQ0NS00NjlmLWFhYmMtMjZhOTA5YzEwMWI3MgA4AEIICKDxh58GEABaLQoba3ViZXJuZXRlcy5pby9tZXRhZGF0YS5uYW1lEg5tZXRhbGxiLXN5c3RlbVoWCgRuYW1lEg5tZXRhbGxiLXN5c3RlbYoBfwoEaGVsbRIGVXBkYXRlGgJ2MSIICKDxh58GEAAyCEZpZWxkc1YxOlUKU3siZjptZXRhZGF0YSI6eyJmOmxhYmVscyI6eyIuIjp7fSwiZjprdWJlcm5ldGVzLmlvL21ldGFkYXRhLm5hbWUiOnt9LCJmOm5hbWUiOnt9fX19QgASDAoKa3ViZXJuZXRlcxoICgZBY3RpdmUaACIA"
    },
    {
      "key": "L3JlZ2lzdHJ5L25hbWVzcGFjZXMvbWluaW8tc3lzdGVt",
      "create_revision": 2902508,
      "mod_revision": 2902508,
      "version": 1,
      "value": "azhzAAoPCgJ2MRIJTmFtZXNwYWNlEqgCCo0CCgxtaW5pby1zeXN0ZW0SABoAIgAqJDk4MjUzZTcwLTg1ZTUtNGMwYy05OTZjLTNiYzY0OWU1MGNlNTIAOABCCAitgJOfBhAAWisKG2t1YmVybmV0ZXMuaW8vbWV0YWRhdGEubmFtZRIMbWluaW8tc3lzdGVtWhQKBG5hbWUSDG1pbmlvLXN5c3RlbYoBfwoEaGVsbRIGVXBkYXRlGgJ2MSIICK2Ak58GEAAyCEZpZWxkc1YxOlUKU3siZjptZXRhZGF0YSI6eyJmOmxhYmVscyI6eyIuIjp7fSwiZjprdWJlcm5ldGVzLmlvL21ldGFkYXRhLm5hbWUiOnt9LCJmOm5hbWUiOnt9fX19QgASDAoKa3ViZXJuZXRlcxoICgZBY3RpdmUaACIA"
    },
    {
      "key": "L3JlZ2lzdHJ5L25hbWVzcGFjZXMvbXlzcWwtY2x1c3Rlcg==",
      "create_revision": 3320516,
      "mod_revision": 3320516,
      "version": 1,
      "value": "azhzAAoPCgJ2MRIJTmFtZXNwYWNlEpICCvcBCg1teXNxbC1jbHVzdGVyEgAaACIAKiRlM2I2NDM2ZS1lYzI5LTRjN2EtOGQ3Mi0yMjBhNGU3MzM2OWQyADgAQggIhdKcnwYQAFosChtrdWJlcm5ldGVzLmlvL21ldGFkYXRhLm5hbWUSDW15c3FsLWNsdXN0ZXKKAX0KDmt1YmVjdGwtY3JlYXRlEgZVcGRhdGUaAnYxIggIhdKcnwYQADIIRmllbGRzVjE6SQpHeyJmOm1ldGFkYXRhIjp7ImY6bGFiZWxzIjp7Ii4iOnt9LCJmOmt1YmVybmV0ZXMuaW8vbWV0YWRhdGEubmFtZSI6e319fX1CABIMCgprdWJlcm5ldGVzGggKBkFjdGl2ZRoAIgA="
    },
    {
      "key": "L3JlZ2lzdHJ5L25hbWVzcGFjZXMvbXlzcWwtaW5ub2RiY2x1c3Rlcg==",
      "create_revision": 3321615,
      "mod_revision": 3321615,
      "version": 1,
      "value": "azhzAAoPCgJ2MRIJTmFtZXNwYWNlEp4CCoMCChNteXNxbC1pbm5vZGJjbHVzdGVyEgAaACIAKiRmMzM3YjYxZC1lNDFhLTQzZjEtYjc5MC0xNzE5YTU5NmFmMTAyADgAQggIj9WcnwYQAFoyChtrdWJlcm5ldGVzLmlvL21ldGFkYXRhLm5hbWUSE215c3FsLWlubm9kYmNsdXN0ZXKKAX0KDmt1YmVjdGwtY3JlYXRlEgZVcGRhdGUaAnYxIggIj9WcnwYQADIIRmllbGRzVjE6SQpHeyJmOm1ldGFkYXRhIjp7ImY6bGFiZWxzIjp7Ii4iOnt9LCJmOmt1YmVybmV0ZXMuaW8vbWV0YWRhdGEubmFtZSI6e319fX1CABIMCgprdWJlcm5ldGVzGggKBkFjdGl2ZRoAIgA="
    },
    {
      "key": "L3JlZ2lzdHJ5L25hbWVzcGFjZXMvb3BlbnNoaWZ0LWNvbnNvbGU=",
      "create_revision": 1356728,
      "mod_revision": 1356728,
      "version": 1,
      "value": "azhzAAoPCgJ2MRIJTmFtZXNwYWNlEpAECvUDChFvcGVuc2hpZnQtY29uc29sZRIAGgAiACokNDliMjFmMjktODEyYi00NWUxLWJhYjktODAzMTc5ZTBkMzY0MgA4AEIICMaC6p4GEABaMAoba3ViZXJuZXRlcy5pby9tZXRhZGF0YS5uYW1lEhFvcGVuc2hpZnQtY29uc29sZWKUAQowa3ViZWN0bC5rdWJlcm5ldGVzLmlvL2xhc3QtYXBwbGllZC1jb25maWd1cmF0aW9uEmB7ImFwaVZlcnNpb24iOiJ2MSIsImtpbmQiOiJOYW1lc3BhY2UiLCJtZXRhZGF0YSI6eyJhbm5vdGF0aW9ucyI6e30sIm5hbWUiOiJvcGVuc2hpZnQtY29uc29sZSJ9fQqKAdsBChlrdWJlY3RsLWNsaWVudC1zaWRlLWFwcGx5EgZVcGRhdGUaAnYxIggIxoLqngYQADIIRmllbGRzVjE6mwEKmAF7ImY6bWV0YWRhdGEiOnsiZjphbm5vdGF0aW9ucyI6eyIuIjp7fSwiZjprdWJlY3RsLmt1YmVybmV0ZXMuaW8vbGFzdC1hcHBsaWVkLWNvbmZpZ3VyYXRpb24iOnt9fSwiZjpsYWJlbHMiOnsiLiI6e30sImY6a3ViZXJuZXRlcy5pby9tZXRhZGF0YS5uYW1lIjp7fX19fUIAEgwKCmt1YmVybmV0ZXMaCAoGQWN0aXZlGgAiAA=="
    },
    {
      "key": "L3JlZ2lzdHJ5L25hbWVzcGFjZXMvdGRlbmdpbmUtc3lzdGVt",
      "create_revision": 2429397,
      "mod_revision": 2429397,
      "version": 1,
      "value": "azhzAAoPCgJ2MRIJTmFtZXNwYWNlErECCpYCCg90ZGVuZ2luZS1zeXN0ZW0SABoAIgAqJGY2ZmRiZTBjLTI4YzQtNDQyMi04MWI2LTQ4NDkxMjg5MDExYzIAOABCCAi0i4efBhAAWi4KG2t1YmVybmV0ZXMuaW8vbWV0YWRhdGEubmFtZRIPdGRlbmdpbmUtc3lzdGVtWhcKBG5hbWUSD3RkZW5naW5lLXN5c3RlbYoBfwoEaGVsbRIGVXBkYXRlGgJ2MSIICLSLh58GEAAyCEZpZWxkc1YxOlUKU3siZjptZXRhZGF0YSI6eyJmOmxhYmVscyI6eyIuIjp7fSwiZjprdWJlcm5ldGVzLmlvL21ldGFkYXRhLm5hbWUiOnt9LCJmOm5hbWUiOnt9fX19QgASDAoKa3ViZXJuZXRlcxoICgZBY3RpdmUaACIA"
    }
  ],
  "count": 16
}
````

key 的值是经过 base64 编码，需要解码后才能看到实际值，如：

```bash
echo "L3JlZ2lzdHJ5L25hbWVzcGFjZXMvdGRlbmdpbmUtc3lzdGVt"| base64 -d
# /registry/namespaces/tdengine-system
```

## etcd 中 kubernetes 的元数据

使用 kubectl 命令获取的 kubernetes 的对象状态实际上是保存在 etcd 中的，使用下面的脚本可以获取 etcd 中的所有 kubernetes 对象的 key：

```bash
#!/bin/bash
# Get kubernetes keys from etcd
export TEMP_ETCDCTL_ENDPOINTS=https://10.244.244.201:2379
export ETCDCTL_API=3
export ETCDCTL_CACERT=/etc/kubernetes/pki/etcd/ca.crt
export ETCDCTL_CERT=/etc/kubernetes/pki/etcd/server.crt
export ETCDCTL_KEY=/etc/kubernetes/pki/etcd/server.key
keys=`etcdctl get /registry --prefix -w json|jq .|grep key|cut -d ":" -f2|tr -d '"'|tr -d ","`
for x in $keys;do
  echo $x|base64 -d|sort
done

```

通过输出的结果可以看到 kubernetes 的原数据是按何种结构包括在 kuberentes 中的，输出结果如下所示：

```bash
...
/registry/clusterroles/system:certificates.k8s.io:kubelet-serving-approver
/registry/clusterroles/system:certificates.k8s.io:legacy-unknown-approver
/registry/clusterroles/system:controller:attachdetach-controller
...
/registry/storageclasses/csi-local-data-path
/registry/storageclasses/nfs-csi
/registry/validatingwebhookconfigurations/cert-manager-webhook
/registry/validatingwebhookconfigurations/metallb-webhook-configuration
/registry/zalando.org/clusterkopfpeerings/mysql-operator
```

可以看到所有的 Kuberentes 的所有元数据都保存在 `/registry` 目录下，下一层就是 API 对象类型（复数形式），再下一层是 `namespace`，最后一层是对象的名字。

以下是 etcd 中存储的 kubernetes 所有的元数据类型：

```bash
ThirdPartyResourceData
apiextensions.k8s.io
apiregistration.k8s.io
certificatesigningrequests
clusterrolebindings
clusterroles
configmaps
controllerrevisions
controllers
daemonsets
deployments
events
horizontalpodautoscalers
ingress
limitranges
minions
monitoring.coreos.com
namespaces
persistentvolumeclaims
persistentvolumes
poddisruptionbudgets
pods
ranges
replicasets
resourcequotas
rolebindings
roles
secrets
serviceaccounts
services
statefulsets
storageclasses
thirdpartyresources
```

