
## 从反向代理提供错误页面，而不是来自上游服务器

如果将 Nginx 作为反向代理运行，并且希望从反向代理本身提供错误页面，需要进行以下代理设置：

```nginx
proxy_intercept_errors on;
```

没有这个，Nginx 会将来自 upstream 的错误页面转发给客户端。

```nginx
error_page 400 /400.html;
location /400.html {
    root   /var/www/error_pages;
    internal;
}

error_page 500 /500.html;
location /500.html {
    root   /var/www/error_pages;
    internal;
}

error_page 502 /502.html;
location /502.html {
    root   /var/www/error_pages;
    internal;
}

error_page 503 /503.html;
location /503.html {
    root   /var/www/error_pages;
    internal;
}

error_page 504 /504.html;
    location /504.html {
    root   /var/www/error_pages;
    internal;
}
```
