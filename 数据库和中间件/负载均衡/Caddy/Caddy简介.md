文档：<https://caddy2.dengxiaolong.com/docs/caddyfile/concepts>

Docker compose 运行 Caddy：<https://caddy2.dengxiaolong.com/docs/running#docker-compose>

```yaml
services:
  caddy:
    image: caddy:<version>
    restart: unless-stopped
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - $PWD/Caddyfile:/etc/caddy/Caddyfile
      - $PWD/site:/srv
      - caddy_data:/data
      - caddy_config:/config
volumes:
  caddy_data:
  caddy_config:
```

