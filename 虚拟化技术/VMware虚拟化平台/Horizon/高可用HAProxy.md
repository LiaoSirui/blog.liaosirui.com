![img](./.assets/高可用HAProxy/image.png)

```conf
! Configuration File for keepalived

global_defs {
   router_id PhotonLB1
   vrrp_skip_check_adv_addr
   vrrp_garp_interval 0
   vrrp_gna_interval 0
}
vrrp_script chk_haproxy {
  script "/usr/bin/kill -0 haproxy"
  interval 2
  weight 2
}
vrrp_instance LB_VIP {
  interface eth0
  state MASTER                  # BACKUP on PhotonLB2
  priority 101                  # 100 on PhotonLB2
  virtual_router_id 11          # same on all peers
  authentication {              # same on all peers
    auth_type AH
    auth_pass Pass1234
  }
  unicast_src_ip 192.168.1.251    # real IP of MASTER peer
  unicast_peer {
    192.168.1.252                 # real IP of BACKUP peer
  }
  virtual_ipaddress {
    192.168.1.250                 # Virtual IP for HAProxy loadbalancer
    192.168.1.20                  # Virtual IP for Horizon
    192.168.1.30                  # Virtual IP for AppVolumes Manager
  }
  track_script {
    chk_haproxy                 # if HAProxy is not running on this peer, start failover
  }
}
```

备用

```
! Configuration File for keepalived

global_defs {
   router_id PhotonLB2
   vrrp_skip_check_adv_addr
   vrrp_garp_interval 0
   vrrp_gna_interval 0
}
vrrp_script chk_haproxy {
  script "/usr/bin/kill -0 haproxy"
  interval 2
  weight 2
}
vrrp_instance LB_VIP {
  interface eth0
  state BACKUP                  # MASTER on PhotonLB1
  priority 100                   # 101 on PhotonLB1
  virtual_router_id 11          # same on all peers
  authentication {              # same on all peers
    auth_type AH
    auth_pass Pass1234
  }
  unicast_src_ip 192.168.1.252    # real IP of BACKUP peer
  unicast_peer {
    192.168.1.251                 # real IP of MASTER peer
  }
  virtual_ipaddress {
    192.168.1.250                 # Virtual IP for HAProxy loadbalancer
    192.168.1.20                  # Virtual IP for Horizon
    192.168.1.30                  # Virtual IP for AppVolumes Manager
  }
  track_script {
    chk_haproxy                 # if HAProxy is not running on this peer, start failover
  }
}
```

## 参考链接

- <https://itpro.peene.be/vmware-horizon-appvolumes-lb-with-haproxy-and-keepalived-on-photonos/>

- <https://docs.vmware.com/en/vRealize-Operations/8.10/vrops-manager-load-balancing/GUID-425274B4-7E57-4A71-A260-317097293231.html>

- <https://www.virtualtothecore.com/balance-multiple-view-connection-servers-using-haproxy/>

- <https://itpro.peene.be/haproxy-health-checks-for-vmware-horizon-appvolumes/>