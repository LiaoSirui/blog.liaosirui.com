## krew 安装

```bash
# kubectl krew
export KREW_ROOT=/opt/krew
export PATH=${KREW_ROOT}/bin${PATH:+:${PATH}}

# install krew
cd $(mktemp -d)
curl -sL "https://github.com/kubernetes-sigs/krew/releases/latest/download/krew-linux_amd64.tar.gz" -o ./krew-linux_amd64.tar.gz
tar zxvf krew-linux_amd64.tar.gz -C .
chmod +x ./krew-linux_amd64

./krew-linux_amd64 install krew
ls -al ${KREW_ROOT}/bin
```

## 插件安装汇总

```bash
export KUBE_KREW_INSTALL_CMD=( "kubectl" "krew" "install" )

kubectl krew index add kvaps https://github.com/kvaps/krew-index

"${KUBE_KREW_INSTALL_CMD[@]}" access-matrix
"${KUBE_KREW_INSTALL_CMD[@]}" ctx
"${KUBE_KREW_INSTALL_CMD[@]}" df-pv
"${KUBE_KREW_INSTALL_CMD[@]}" doctor
"${KUBE_KREW_INSTALL_CMD[@]}" exec-as
"${KUBE_KREW_INSTALL_CMD[@]}" grep
"${KUBE_KREW_INSTALL_CMD[@]}" ice
"${KUBE_KREW_INSTALL_CMD[@]}" iexec
"${KUBE_KREW_INSTALL_CMD[@]}" images
"${KUBE_KREW_INSTALL_CMD[@]}" ingress-nginx
"${KUBE_KREW_INSTALL_CMD[@]}" kvaps/node-shell
"${KUBE_KREW_INSTALL_CMD[@]}" minio
"${KUBE_KREW_INSTALL_CMD[@]}" neat
"${KUBE_KREW_INSTALL_CMD[@]}" ns
"${KUBE_KREW_INSTALL_CMD[@]}" oidc-login
"${KUBE_KREW_INSTALL_CMD[@]}" pod-logs
"${KUBE_KREW_INSTALL_CMD[@]}" pod-shell
"${KUBE_KREW_INSTALL_CMD[@]}" rbac-lookup
"${KUBE_KREW_INSTALL_CMD[@]}" rbac-view
"${KUBE_KREW_INSTALL_CMD[@]}" resource-capacity
"${KUBE_KREW_INSTALL_CMD[@]}" rm-standalone-pods
"${KUBE_KREW_INSTALL_CMD[@]}" tail
"${KUBE_KREW_INSTALL_CMD[@]}" tree
"${KUBE_KREW_INSTALL_CMD[@]}" view-allocations
"${KUBE_KREW_INSTALL_CMD[@]}" view-cert
"${KUBE_KREW_INSTALL_CMD[@]}" view-secret
"${KUBE_KREW_INSTALL_CMD[@]}" view-serviceaccount-kubeconfig
"${KUBE_KREW_INSTALL_CMD[@]}" view-utilization
"${KUBE_KREW_INSTALL_CMD[@]}" warp
"${KUBE_KREW_INSTALL_CMD[@]}" whoami
```
