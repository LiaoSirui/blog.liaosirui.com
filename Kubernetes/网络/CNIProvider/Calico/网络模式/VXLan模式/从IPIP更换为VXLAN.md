## UDP 端口检测流程

（此处以测试 4789 UDP 为例）

先部署一个 daemonset 用来监听 4789 的 udp 端口，并返回信息

需要运行如下代码

运行一个 daemonset （已上传多架构镜像 ，该镜像可用于 arm 机器）

```yaml
# 镜像为 python3

apiVersion: apps/v1
kind: DaemonSet
metadata:
  name: listen-udp-4789
  labels:
    app: listen-udp-4789
spec:
  selector:
    matchLabels:
      app: listen-udp-4789
  template:
    metadata:
      labels:
        app: listen-udp-4789
    spec:
      nodeSelector:
         
      hostNetwork: true
      terminationGracePeriodSeconds: 1
      tolerations:
        - operator: Exists
      imagePullSecrets:
        - name: aipaas-image-pull-secrets
      containers:
        - name: listen-udp-4789
          image: python:3.9.17
          command: ["python3", "listen.py"]
          securityContext:
            privileged: true
          workingDir: /data
          volumeMounts:
            - name: py
              readOnly: true
              mountPath: /data
      volumes:
      - name: py
        configMap:
          name: listen-udp-4789
          defaultMode: 420
```

获取所有节点的 IP 用于 ansible 执行

```bash
kubectl get nodes -o wide |awk '{print $6}' |grep -v "INTERNAL-IP" > hosts
```

确认所有节点安装 python3 和 nc

```bash
ansible -i hosts all -m shell -a "yum install -y nmap-ncat python3"
 
# 确定 nc
ansible -i hosts all -m shell -a "nc --version"
 
# 确定 python3
ansible -i hosts all -m shell -a "python3 --version"
```

新建一个探测脚本

```python
# udp_connectivity.py
import argparse
import socket
 
 
def test_udp_connectivity(target_host, target_port):
    try:
        udp_socket = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
        udp_socket.settimeout(5) # 建议超时时间为 5 s
        udp_socket.sendto(b"Test", (target_host, target_port))
        data, _ = udp_socket.recvfrom(1024)
        udp_socket.close()
        return True, data.decode()
    except socket.timeout:
        return False, "Timeout"
    except socket.error as e:
        return False, str(e)
 
def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--target_host", required=True, help="Target host")
    parser.add_argument("--target_port", required=True, type=int, help="Target port")
    args = parser.parse_args()
 
    target_host = args.target_host
    target_port = args.target_port
 
    success, message = test_udp_connectivity(target_host, target_port)
 
    if success:
        print(f"UDP port {target_port} connectivity to {target_host} successful, {message}")
    else:
        print(f"UDP port {target_port} connectivity to {target_host} failed: {message}")
 
 
if __name__ == "__main__":
    main()
```

拷贝此文件到所有节点

```bash
ansible -i hosts all -m copy -a "src=udp_connectivity.py dest=/root/udp_connectivity.py"
```

创建一个如下的 playbook 用来测试

```
-``-``-``-` `name: Test UDP port connectivity between cluster nodes`` ``hosts: ``all`` ``gather_facts: false`` ``vars``:``  ``target_port: ``4789` ` ``tasks:``  ``-` `name: Generate combinations of cluster nodes``   ``set_fact:``    ``node_combinations: ``"{{ node_combinations | default([]) + [ [item.0, item.1] ] }}"``   ``with_cartesian:``    ``-` `"{{ inventory_hostname }}"``    ``-` `"{{ groups['all'] }}"``   ``# when: item.0 != item.1` `  ``-` `name: Test UDP port connectivity``   ``shell: python3 ``/``root``/``udp_connectivity.py ``-``-``target_host``=``"{{ inventory_hostname }}"` `-``-``target_port``=``"{{ target_port }}"``   ``loop: ``"{{ node_combinations }}"``   ``register: result` `  ``-` `name: ``Print` `UDP port connectivity result``   ``debug:``    ``msg: ``"UDP port {{ target_port }} connectivity from {{ item.item[1] }} to {{ item.item[0] }}: {{ item.stdout }}"``   ``loop: ``"{{ result.results }}"
```

执行并记录结果

```
ansible``-``playbook ``-``i hosts udp_test_playbook.yml > res.txt
```

搜索日志中的 `failed:` 就可以看到无法连通的节点组

成功示例

```
ok: [``10.48``.``104.45``] ``=``> (item``=``None``) ``=``> {``  ``"msg"``: ``"UDP port 14789 connectivity from 10.48.104.45 to 10.48.104.44: UDP port 14789 connectivity to 10.48.104.45 successful, Server response"``}
```



失败示例

```
ok: [``10.101``.``221.39``] ``=``> (item``=``None``) ``=``> {``  ``"msg"``: ``"UDP port 14789 connectivity from 10.101.221.39 to 10.48.104.44: UDP port 14789 connectivity to 10.101.221.39 failed: Timeout"``}
```

测试完成后删除 daemonset 或者给 daemonset 增加 nodeSelector（例如 disable: yes）

## 执行变更

 （1）确定开启内核模块，所有节点的 `/usr/bin/kubelet-pre-start.sh` 文件增加：

```
modprobe ``-``-` `vxlan` `# sed -i '7imodprobe -- vxlan' /usr/bin/kubelet-pre-start.sh
```

（2）修改calico config

```
kubectl edit configmaps ``-``n kube``-``system calico``-``config
```

变更如下

```
calico_backend: bird` `-``>` `calico_backend: vxlan
```

（3）修改 calico-node

```
kubectl edit daemonsets.apps ``-``n kube``-``system calico``-``node
```

变更如下：

```
-` `name: CALICO_IPV4POOL_IPIP`` ``value: Always` `-``>` `-` `name: CALICO_IPV4POOL_IPIP`` ``value: Never``-` `name: CALICO_IPV4POOL_IPIP`` ``value: Never` `# 如果需要修改端口，则：``-` `name: FELIX_VXLANPORT`` ``value: ``"14789"
```

readinessProbe 修改如下：

```
readinessProbe:`` ``exec``:``  ``command:``  ``-` `/``bin``/``calico``-``node``  ``# - -bird-ready``  ``-` `-``felix``-``ready`` ``failureThreshold: ``3`` ``periodSeconds: ``10`` ``successThreshold: ``1`` ``timeoutSeconds: ``1
```

注意 daemonset 需要先执行删除，然后再 apply ，否则不生效

（4）查看网卡

calico 会创建如下的网卡

![img](http://wiki.bigquant.ai/download/attachments/373296143/image2023-7-5_13-54-55.png?version=1&modificationDate=1688536733923&api=v2)

（5）等待所有节点网络重启完毕后，开始进行 coredns 的重启，防止出现不正常的情况

```
kubectl rollout restart deployment ``-``n kube``-``system coredns
```

（6）确定 ingress 生效，从浏览器访问 ingress，说明 ingress pod 访问其他的 pod 生效

（7）从其他节点使用 curl 访问 ingress，从而验证到 master 至其他节点生效

（8）确定路由

```
ip r | grep ``-``vi vxlan` `ip r | grep ``-``vi tunl0``# 返回为空说明成功
```

## Pod 访问测试

新建一个 Daemonset 并调度，进行测试

```
apiVersion: apps``/``v1``kind: DaemonSet``metadata:`` ``name: vxlan``-``test`` ``namespace: bigquant``-``console`` ``labels:``  ``app: vxlan``-``test``spec:`` ``selector:``  ``matchLabels:``   ``app: vxlan``-``test`` ``template:``  ``metadata:``   ``labels:``    ``app: vxlan``-``test``  ``spec:``   ``nodeSelector:``    ``kubernetes.io``/``os: linux``   ``tolerations:``    ``-` `operator: Exists``   ``imagePullSecrets:``    ``-` `name: aipaas``-``image``-``pull``-``secrets``   ``affinity:``    ``nodeAffinity:``     ``requiredDuringSchedulingIgnoredDuringExecution:``      ``nodeSelectorTerms:``       ``-` `matchExpressions:``         ``-` `key: kubernetes.io``/``hostname``          ``operator: NotIn``          ``values:``           ``-` `"xxx"``   ``containers:``    ``-` `name: test``     ``# image: artifactory.csc.com.cn/csc-docker-prod/paas/bigquant-console/python:3.9.17``     ``image: artifactory.csc.com.cn``/``csc``-``docker``-``sit``/``paas``/``bigquant``-``console``/``python:``3.9``.``17``     ``imagePullPolicy: IfNotPresent``     ``command:``      ``-` `/``bin``/``sh``     ``args:``      ``-` `-``c``      ``-` `python3 ``-``m http.server ``8081``     ``resources:``      ``limits:``       ``cpu: ``1000m``       ``memory: ``2000Mi``      ``requests:``       ``cpu: ``1000m``       ``memory: ``2000Mi``     ``securityContext:``      ``privileged: true``     ``env:``      ``-` `name: POD_NAME``       ``valueFrom:``        ``fieldRef:``         ``fieldPath: metadata.name``   
```

新建的 ds 增加一个 svc

```
-``-``-``apiVersion: v1``kind: Service``metadata:`` ``name: vxlan``-``test``-``headless`` ``namespace: bigquant``-``console`` ``labels:``  ``app: vxlan``-``test``spec:`` ``type``: ClusterIP`` ``clusterIP: ``None`` ``ports:``  ``-` `name: http``   ``protocol: TCP``   ``port: ``8081``   ``targetPort: ``8081`` ``selector:``  ``app: vxlan``-``test` `-``-``-``apiVersion: v1``kind: Service``metadata:`` ``name: vxlan``-``test`` ``namespace: bigquant``-``console`` ``labels:``  ``app: vxlan``-``test``spec:`` ``type``: ClusterIP`` ``ports:``  ``-` `name: http``   ``protocol: TCP``   ``port: ``8081``   ``targetPort: ``8081`` ``selector:``  ``app: vxlan``-``test
```

启动完成后每个节点都会有 pod 存在，并监听 4789 端口

生成一份 ip pod 列表

```
oldifs``=``"$IFS"` `IFS``=``$``'\n'` `for` `line ``in` `$(kubectl get pod ``-``n bigquant``-``console ``-``l app``=``vxlan``-``test ``-``o wide |grep ``-``v NAME)``do``  ``pod_ip``=``$(echo $line|awk ``'{print $6}'``)``  ``pod_node``=``$(echo $line|awk ``'{print $7}'``)``  ``echo ``"${pod_node} ${pod_ip}"` `>> check``-``vxlan.``list``done ` `IFS``=``"$oldifs"
```

使用如下脚本，在 master 节点探测其他节点是否返回：

```
#!/usr/bin/env` `while` `read ``-``r line``do``  ``echo ``"=="``  ``pod_ip``=``$(echo $line|awk ``'{print $2}'``)``  ``pod_node``=``$(echo $line|awk ``'{print $1}'``)``  ``pod_url``=``"http://$pod_ip:8081"``  ``echo cheking ... pod_ip ${pod_ip} pod_node ${pod_node}, ${pod_url}``  ``if` `curl ``-``-``connect``-``timeout ``10` `-``m ``20` `-``sSf ``"http://${pod_ip}:8081"` `> ``/``dev``/``null; then``    ``echo ``"${pod_ip} Port is up"``  ``else``    ``echo ``"${pod_ip} Port is down"``  ``fi``done < ``/``root``/``check``-``vxlan.``list
```

拷贝到每个节点

```
ansible ``-``i hosts ``all` `-``m copy ``-``a ``"src=check-vxlan.sh dest=/root/check-vxlan.sh"``ansible ``-``i hosts ``all` `-``m copy ``-``a ``"src=check-vxlan.list dest=/root/check-vxlan.list"
```

使用如下的 playbook

```
-``-``-``-` `name: Test VXLan port connectivity between cluster nodes`` ``hosts: ``all`` ``gather_facts: false`` ` ` ``tasks:``  ``-` `name: Test VXLan port connectivity``   ``shell: bash ``/``root``/``check``-``vxlan.sh``   ``register: result``   ``ignore_errors: true` `  ``-` `name: ``Print` `command result``   ``debug:``    ``var: result.stdout_lines
```

执行并收集结果

```
ansible``-``playbook ``-``i hosts vxlan_test_playbook.yml > vxlan``-``res.txt
```

测试结果示例

```
ok: [``10.48``.``104.45``] ``=``> {``  ``"result.stdout_lines"``: [``    ``"=="``,``    ``"cheking ... pod_ip 100.99.107.36 pod_node node04.xc.bigaiv2.csc.com, http://100.99.107.36:8081"``,``    ``"100.99.107.36 Port is up"``,``    ``"=="``,``    ``"cheking ... pod_ip 100.68.176.149 pod_node inward-node01.xc.bigaiv2.csc.com, http://100.68.176.149:8081"``,``    ``"100.68.176.149 Port is up"``,``    ``"=="``,``    ``"cheking ... pod_ip 100.93.8.146 pod_node master03.xc.bigaiv2.csc.com, http://100.93.8.146:8081"``,
```

如果出现 down 字样，说明该节点有问题