## Whois exporter

域名 whois 信息导出，通常用于域名过期检查

可选项目：

- <https://github.com/caarlos0/domain_exporter>

常用的 whois 查询站点：

- <https://whois.chinaz.com/>
- <https://whois.aliyun.com>
- <https://www.alibabacloud.com/zh/whois>
- <https://domainr.com/>

## Whois 协议

RFC812 定义了一个非常简单的 Internet 信息查询协议 ——WHOIS 协议。其基本内容是，先向服务器的 TCP 端口 43 建立一个连接，发送查询关 键字并加上回车换行，然后接收服务器的查询结果

```python
"""Whois."""

import socket

from rich import print

s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)

s.connect(("whois.internic.net", 43))
s.send(b"liaosirui.com \r\n")

while 1:
    v = s.recv(1024)
    if not v:
        break
    print(v)

s.close()

```

Python 获取 whois 信息

安装包

```bash
uv add python-whois
```

获取 whois 信息

```python
from datetime import UTC, datetime

import whois
from rich import print


def get_remaining_days(domain: str) -> int | None:
    """Get domain remaining days."""
    try:
        domain_info = whois.whois(domain)
        print(f"域名信息：{domain_info}")
        if "expiration_date" in domain_info:
            registrar: str = domain_info["registrar"]
            domain_name: str = domain_info["domain_name"]
            expiration_date: datetime = domain_info["expiration_date"]
            remaining_days: int = (expiration_date - datetime.now(tz=UTC)).days
            print(f"续费服务：{registrar}")
            print(f"续费域名：{domain_name}")
            print(f"到期日期：{(expiration_date)}")
            print(f"剩余天数：【{remaining_days}天】")
            return remaining_days
        else:
            return None
    except Exception as e:
        print(f"获取 {domain} 域名 whois 信息时出错：{e}")
        return None


if __name__ == "__main__":
    remaining_days = get_remaining_days("liaosirui.com")
    remaining_days = get_remaining_days("alpha-quant.tech")

```

## 阿里云 whois

- <https://help.aliyun.com/zh/dws/user-guide/whois-lookup-1>