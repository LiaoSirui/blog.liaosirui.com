nginx-acme 是一个 NGINX 模块，实现了自动证书管理 (ACMEv2) 协议。

- <https://github.com/nginx/nginx-acme/blob/main/README.md>

```bash
load_module modules/ngx_http_acme_module.so;
```

（1）配置 ACME 服务器和共享内存

```nginx
acme_issuer letsencrypt {
    uri         https://acme-v02.api.letsencrypt.org/directory;
    # contact     admin@alpha-quat.tech;
    state_path  /var/cache/nginx/acme-letsencrypt; 
    accept_terms_of_service; 
}
acme_shared_zone zone=acme_shared:1M; 
```

（2）配置 HTTP-01 需要的 Web

```nginx
server { 
    # listener on port 80 is required to process ACME HTTP-01 challenges 
    listen 80; 

    location / { 
        #Serve a basic 404 response while listening for challenges 
        return 404; 
    } 
}
```

（3）配置 SSL 服务

Let's Encrypt 为了校验用户是否有权管理某个域名，支持 DNS、HTTP-01 等校验机制。

因为 Let's Encrypt 证书有效期是 90 天，Nginx 支持自动续期是它最大的价值。

```nginx
server { 
    listen 443 ssl;
    listen [::]:443 ssl;
    server_name test.alpha-quat.tech;
    acme_certificate      letsencrypt;
    ssl_certificate       $acme_certificate;
    ssl_certificate_key   $acme_certificate_key;
    ssl_certificate_cache max=2;
}
```

