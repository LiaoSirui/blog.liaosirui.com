## Certbot 简介

Certbot 是一个申请 Let’s Encrypt 免费 SSL 的工具

## HTTP-01

```bash
docker run --network host -it --rm --name certbot \
    -v "./config:/etc/letsencrypt" \
    -v "./www:/var/www/certbot" \
    -v "./data:/var/lib/letsencrypt" \
    docker.io/certbot/certbot:v4.0.0 \
        certonly \
        -d www.alpha-quant.tech \
        -d alpha-quant.tech \
        --webroot --webroot-path /var/www/certbot/
```

## DNS-01

在使用文件验证申请 SSL 证书时会使用 80 端口做文件校验，但是有时候域名并非会用到 80，而会用到一些非 80 的端口，这个时候使用 DNS 验证的形式申请证书会更方便一些

```bash
docker run --network host -it --rm --name certbot \
    -v "./config:/etc/letsencrypt" \
    -v "./www:/var/www/certbot" \
    -v "./data:/var/lib/letsencrypt" \
    docker.io/certbot/certbot:v4.0.0 \
        certonly \
        -d www.alpha-quant.tech \
        -d alpha-quant.tech \
        --manual \
        --preferred-challenges dns
```

按照要求添加 DNS 解析

```bash
Please deploy a DNS TXT record under the name: # 需要将以下 TXT 记录添加 DNS 中

_acme-challenge.www.alpha-quant.tech.

with the following value:
```

默认情况下证书有效期是 3 个月，可以使用以下命令进行自动续费

```bash
certbot renew --quiet
```
