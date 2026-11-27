在 CoreDNS中实现类似 nip.io 或 sslip.io 的泛域名解析（即提取域名中的 IP 地址并直接返回对应的 A/AAAA 记录）
```corefile
nip.local:53 {
    template IN A {
        match (^|\.)(?P<a>\d{1,3})[\.-](?P<b>\d{1,3})[\.-](?P<c>\d{1,3})[\.-](?P<d>\d{1,3})\.nip\.local\.$
        answer "{{ .Name }} 60 IN A {{ .Group.a }}.{{ .Group.b }}.{{ .Group.c }}.{{ .Group.d }}"
        fallthrough
    }
}
```

`nip.io` 同时支持 `10-0-0-1.nip.io`（常用于避免通配符 SSL 证书层级限制）和 `10.0.0.1.nip.io`