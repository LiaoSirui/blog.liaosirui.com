## sendfile 在 nginx 中的配置

官方文档：

- <http://nginx.org/en/docs/http/ngx_http_core_module.html#sendfile>

```nginx
location /video/ {
   sendfile       on;
   tcp_nopush     on;
   aio            on;
}
```

如下：

![sendfile](.assets/sendfile/02f64f12720a4fdabcdcb5f9f72510f2.png)

## 参考文档

- <https://www.sobyte.net/post/2022-08/nginx-send/>