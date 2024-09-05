## 架构简介

![img](./.assets/高可用HAProxy/image.png)

## HAProxy 配置

```ini
# HAProxy configuration

# Global settings
#---------------------------------------------------------------------
global
    maxconn     20000
    log         /dev/log local0 info
    # debug
    # log         127.0.0.1 local0 debug 
    chroot      /var/lib/haproxy
    pidfile     /var/run/haproxy.pid
    user        haproxy
    group       haproxy
    daemon

    # turn on stats unix socket
    stats socket /var/lib/haproxy/stats

#---------------------------------------------------------------------
# common defaults that all the 'listen' and 'backend' sections will
# use if not designated in their block
#---------------------------------------------------------------------
defaults
    timeout tunnel          1h
    timeout client-fin      30s
    timeout queue           1m
    timeout connect         10s
    timeout client          300s
    timeout server          300s
    timeout http-keep-alive 10s
    timeout check           10s
    maxconn                 200000

listen stats
    mode http
    bind :9000
    stats enable
    stats uri /

frontend route-80
    mode http
    bind *:80
    option httplog
    redirect scheme https if !{ ssl_fc }

frontend route-443
    mode tcp
    bind *:443
    option tcplog
    timeout client 91s
    default_backend route-443

backend route-443
    mode tcp
    option ssl-hello-chk
    balance leastconn
    stick-table type ip size 1m expire 200m
    stick on src
    option httpchk HEAD /favicon.ico
    timeout server 91s

    server      cs1 192.168.52.12:443  weight 1 check check-ssl verify none inter 30s fastinter 5s rise 5 fall 2
    server      cs2 192.168.52.13:443  weight 1 check check-ssl verify none inter 30s fastinter 5s rise 5 fall 2
    server      cs3 192.168.52.14:443  weight 1 check check-ssl verify none inter 30s fastinter 5s rise 5 fall 2

```

## KeepAlived 配置

检测脚本

```bash
#!/bin/bash
err=0
for k in $(seq 1 3)
do
    check_code=$(pgrep haproxy)
    if [[ $check_code == "" ]]; then
        err=$(expr $err + 1)
        sleep 1
        continue
    else
        err=0
        break
    fi
done

if [[ $err != "0" ]]; then
    echo "systemctl stop keepalived"
    /usr/bin/systemctl stop keepalived
    exit 1
else
    exit 0
fi

# /etc/keepalived/check_haproxy.bash
```

主

```ini
! Configuration File for keepalived
global_defs {
    router_id VMHORIZON
    script_user root
    enable_script_security
}
vrrp_script chk_haproxy {
    script "/etc/keepalived/check_haproxy.bash"
    interval 5
    weight -5
    fall 2
    rise 1
}
vrrp_instance VI_1 {
    state MASTER
    interface ens33
    mcast_src_ip 192.168.52.16
    virtual_router_id 11
    priority 100
    advert_int 2
    authentication {
        auth_type PASS
        auth_pass HORIZON_HA_KA_AUTH
    }
    virtual_ipaddress {
        192.168.52.11/24
    }
    track_script {
        chk_haproxy
    }
}

```

备用 1

```ini
! Configuration File for keepalived
global_defs {
    router_id VMHORIZON
    script_user root
    enable_script_security
}
vrrp_script chk_haproxy {
    script "/etc/keepalived/check_haproxy.bash"
    interval 5
    weight -5
    fall 2
    rise 1
}
vrrp_instance VI_1 {
    state BACKUP
    interface ens33
    mcast_src_ip 192.168.52.15
    virtual_router_id 11
    priority 99
    advert_int 2
    authentication {
        auth_type PASS
        auth_pass HORIZON_HA_KA_AUTH
    }
    virtual_ipaddress {
        192.168.52.11/24
    }
    track_script {
        chk_haproxy
    }
}

```

备用 2

```ini
! Configuration File for keepalived
global_defs {
    router_id VMHORIZON
    script_user root
    enable_script_security
}
vrrp_script chk_haproxy {
    script "/etc/keepalived/check_haproxy.bash"
    interval 5
    weight -5
    fall 2
    rise 1
}
vrrp_instance VI_1 {
    state BACKUP
    interface ens33
    mcast_src_ip 192.168.52.17
    virtual_router_id 11
    priority 98
    advert_int 2
    authentication {
        auth_type PASS
        auth_pass HORIZON_HA_KA_AUTH
    }
    virtual_ipaddress {
        192.168.52.11/24
    }
    track_script {
        chk_haproxy
    }
}

```

## Horizon 设置

更新代理域名

```
C:\Program Files\VMware\VMware View\Server\sslgateway\conf\locked.properties
```

设置

```
balancedHost=192.168.52.11
```

## 参考链接

- <https://itpro.peene.be/vmware-horizon-appvolumes-lb-with-haproxy-and-keepalived-on-photonos/>
- <https://docs.vmware.com/en/vRealize-Operations/8.10/vrops-manager-load-balancing/GUID-425274B4-7E57-4A71-A260-317097293231.html>
- <https://www.virtualtothecore.com/balance-multiple-view-connection-servers-using-haproxy/>