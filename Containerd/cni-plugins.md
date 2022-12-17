下载 cni

```
wget https://github.com/containernetworking/plugins/releases/download/v1.1.0/cni-plugins-linux-amd64-v1.1.0.tgz
mkdir -p /usr/local/cni-plugins
tar xvf cni-plugins-linux-amd64-v1.1.0.tgz -C /usr/local/cni-plugins


mkdir -p /etc/cni/net.d

cat >/etc/cni/net.d/10-my_net.conf <<EOF
{
    "cniVersion": "0.2.0",
    "name": "my_net",
    "type": "bridge",
    "bridge": "cni0",
    "isGateway": true,
    "ipMasq": true,
    "ipam": {
        "type": "host-local",
        "subnet": "10.22.0.0/16",
        "routes": [
            { "dst": "0.0.0.0/0" }
        ]
    }
}
EOF

cat >/etc/cni/net.d/99-loopback.conf <<EOF
{
    "cniVersion": "0.2.0",
    "name": "lo",
    "type": "loopback"
}
EOF
```
