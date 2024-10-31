启动失败报错

```bash
service-control --start vmvare-vpxd

cat /var/log/vmware/vpxd/vpxd.log |grep "error"
```

- <https://shuttletitan.com/vsphere/vcenter-gui-error-no-healthy-upstream-vcenter-server-vmware-vpxd-service-would-not-start/>

修改域

```bash
cmsso-util domain-repoint -m execute --src-emb-admin Administrator --dest-domain-name vsphere.local
```

