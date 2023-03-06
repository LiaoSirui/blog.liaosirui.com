```bash
NODE=node-foobar
kubectl run pwru \
    --image=cilium/pwru:latest \
    --privileged=true \
    --attach=true -i=true --tty=true --rm=true \
    --overrides='{"apiVersion":"v1","spec":{"nodeSelector":{"kubernetes.io/hostname":"'$NODE'"}, "hostNetwork": true, "hostPID": true}}' \
    -- --filter-dst-ip=1.1.1.1 --output-tuple
```

