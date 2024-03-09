```ini
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
    mode                    http
    log                     global
    option                  httplog
    option                  dontlognull
    # option http-server-close
    option forwardfor       except 127.0.0.0/8
    option                  redispatch
    retries                 3
    timeout http-request    10s

    timeout tunnel 1h
    timeout client-fin 30s
    timeout queue           1m
    timeout connect         10s
    timeout client          300s
    timeout server          300s
    timeout http-keep-alive 10s
    timeout check           10s
    maxconn                 200000

listen stats
    bind :9000
    mode http
    stats enable
    stats uri /

frontend route-80
    bind *:80
    acl denylist src 171.83.9.9 113.108.77.24 139.224.229.201
    tcp-request connection reject if denylist
    redirect scheme https if !{ ssl_fc }
    capture request header Host len 20
    capture request header Referer len 60
    default_backend route-80
    mode http
    option tcplog
    option httplog

backend route-80
    balance source
    mode http
    option forwardfor
    server      master1 192.168.146.211:80  send-proxy  check inter 3000 fall 3 rise 5
    server      master1 192.168.146.212:80  send-proxy  check inter 3000 fall 3 rise 5
    server      master1 192.168.146.213:80  send-proxy  check inter 3000 fall 3 rise 5

frontend route-443
    bind *:443
    acl denylist src 171.83.9.9 113.108.77.24 139.224.229.201
    tcp-request connection reject if denylist
    default_backend route-443
    mode tcp
    option tcplog
    option httplog

backend route-443
    balance source
    option forwardfor
    mode tcp
    server      master1 192.168.146.211:443  send-proxy  check inter 3000 fall 3 rise 5
    server      master2 192.168.146.212:443  send-proxy  check inter 3000 fall 3 rise 5
    server      master3 192.168.146.213:443  send-proxy  check inter 3000 fall 3 rise 5

frontend route-6443
    bind *:6443 npn spdy/2 alpn h2,http/1.1
    #bind *:6443
    default_backend route-6443
    mode tcp
    option forwardfor

backend route-6443
    balance source
    mode tcp
    option forwardfor
    maxconn         8000
    timeout client  60s
    server      master1 192.168.146.211:6443   check inter 3000 fall 3 rise 5
    server      master2 192.168.146.212:6443   check inter 3000 fall 3 rise 5
    server      master3 192.168.146.213:6443   check inter 3000 fall 3 rise 5
```

