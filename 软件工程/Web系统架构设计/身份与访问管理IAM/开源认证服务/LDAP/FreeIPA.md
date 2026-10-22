FreeIPA 是一个用于 Linux/Unix 环境的开源身份管理系统，它提供集中式的账号管理和身份验证，其集成 389 目录服务器（一种 LDAP 实现）、NTP、DNS、MIT Kerberos 等

```yaml
services:
  freeipa:
    image: harbor.alpha-quant.tech/3rd/docker.io/freeipa/freeipa-server:rocky-9-4.12.2
    domainname: freeipa.alpha-quant.tech
    container_name: freeipa
    ports:
      # - "11080:80/tcp"
      - "80:80/tcp"
      - "443:443/tcp"
      # DNS
      - "53:53/tcp"
      - "53:53/udp"
      # LDAP(S)
      - "389:389/tcp"
      - "636:636/tcp"
      # Kerberos
      - "88:88/tcp"
      - "88:88/udp"
      - "464:464/tcp"
      - "464:464/udp"
      # NTP
      - "123:123/udp"
    dns:
      - 114.114.114.114
    tty: true
    stdin_open: true
    environment:
      IPA_SERVER_HOSTNAME: freeipa.alpha-quant.tech
      TZ: "Asia/Shanghai"
    command:
      - --domain=freeipa.alpha-quant.tech
      - --realm=freeipa.alpha-quant.tech
      # freeipa 的 admin 管理员账号
      - --admin-password=123456.com
      - --http-pin=123456
      - --dirsrv-pin=123456
      - --ds-password=12345678
      - --no-dnssec-validation
      - --no-host-dns
      - --setup-dns
      - --auto-forwarders
      - --allow-zone-overlap
      # 自动无人工干预安装
      - --unattended
    cap_add:
      - SYS_TIME
      - NET_ADMIN
    volumes:
      - /etc/localtime:/etc/localtime:ro
      - /sys/fs/cgroup:/sys/fs/cgroup:ro
      - ./free-ipa/data:/data
      - ./free-ipa/logs:/var/logs
    # sysctls:
    #   - net.ipv6.conf.all.disable_ipv6=0
    #   - net.ipv6.conf.lo.disable_ipv6=0
    security_opt:
      - "seccomp:unconfined"
    networks:
      - freeipa
networks:
  freeipa:
    driver: bridge
    ipam:
      driver: default
      config:
        - subnet: 172.28.1.0/24
          gateway: 172.28.1.254

```

