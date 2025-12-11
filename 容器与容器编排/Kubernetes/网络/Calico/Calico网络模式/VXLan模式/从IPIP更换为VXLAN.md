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

```yaml
---
- name: Test UDP port connectivity between cluster nodes
  hosts: all
  gather_facts: false
  vars:
    target_port: 14789
    tasks:
    - name: Generate combinations of cluster nodes
      set_fact:
        node_combinations: "{{ node_combinations | default([]) + [ [item.0, item.1] ] }}"
      with_cartesian:
        - "{{ inventory_hostname }}"
        - "{{ groups['all'] }}"
      # when: item.0 != item.1
 
    - name: Test UDP port connectivity
      shell: python3 /root/udp_connectivity.py --target_host="{{ inventory_hostname }}" --target_port="{{ target_port }}"
      loop: "{{ node_combinations }}"
      register: result
 
    - name: Print UDP port connectivity result
      debug:
        msg: "UDP port {{ target_port }} connectivity from {{ item.item[1] }} to {{ item.item[0] }}: {{ item.stdout }}"
      loop: "{{ result.results }}"
```

执行并记录结果

```shell
ansible-playbook -i hosts udp_test_playbook.yml > res.txt
```

搜索日志中的 `failed:` 就可以看到无法连通的节点组

成功示例

```bash
ok: [10.48.104.45] => (item=None) => {
    "msg": "UDP port 114789 connectivity from 10.48.104.45 to 10.48.104.44: UDP port 114789 connectivity to 10.48.104.45 successful, Server response"
}
```

失败示例

```bash
ok: [10.101.221.39] => (item=None) => {
    "msg": "UDP port 114789 connectivity from 10.101.221.39 to 10.48.104.44: UDP port 114789 connectivity to 10.101.221.39 failed: Timeout"
}

```

测试完成后删除 daemonset 或者给 daemonset 增加 nodeSelector（例如 disable: yes）

## 执行变更

 （1）确定开启内核模块，所有节点的执行：

```bash
modprobe -- vxlan
```

（2）修改 calico config

```yaml
calico_backend: bird
 
->
 
calico_backend: vxlan
```

（3）删除 calico ippool

```bash
kubectl delete ippool default-ipv4-ippool
```

（4）配置 NetworkManager

生成一个配置文件

```ini
[keyfile]
unmanaged-devices=interface-name:cali*;interface-name:tunl*;interface-name:vxlan.calico;interface-name:vxlan-v6.calico;interface-name:wireguard.cali;interface-name:wg-v6.cali
```

拷贝到每个节点

```bash
ansible -i hosts all -m copy -a "src=calico.conf dest=/etc/NetworkManager/conf.d/calico.conf"
```

执行变更

```bash
ansible -i hosts all -m shell -a "systemctl daemon-reload && systemctl restart NetworkManager"
```

（5）建议清理 bird 路由

```bash
ansible -i hosts all -m shell -a "ip r |grep bird |awk '{printf(\"ip r d %s\n\", \$0)}' | bash"
```

（6）修改 calico-node

```yaml
- name: CALICO_IPV4POOL_IPIP
  value: Always
 
->
 
- name: CALICO_IPV4POOL_IPIP
  value: Never
- name: CALICO_IPV4POOL_IPIP
  value: Never
 
# 如果需要修改端口，则：
- name: FELIX_VXLANPORT
  value: "14789"
```

readinessProbe 修改如下：

```yaml
readinessProbe:
  exec:
    command:
    - /bin/calico-node
    # - -bird-ready
    - -felix-ready
  failureThreshold: 3
  periodSeconds: 10
  successThreshold: 1
  timeoutSeconds: 1
```

注意 daemonset 需要先执行删除，然后再 apply ，否则不生效

（7）查看网卡；calico 会创建 `calico.vxlan`

（8）等待所有节点网络重启完毕后，开始进行 coredns 的重启，防止出现不正常的情况

```bash
kubectl rollout restart deployment -n kube-system coredns
```

（9）检查

```bash
ip r | grep -vi vxlan
# ansible -i hosts all -m shell -a "ip r |grep vxlan | wc -l"

ip r | grep -vi bird
# 返回为空说明成功
```

## Pod 访问测试

新建一个 Daemonset 并调度，进行测试

```yaml
aapiVersion: apps/v1
kind: DaemonSet
metadata:
  name: vxlan-test
  labels:
    app: vxlan-test
spec:
  selector:
    matchLabels:
      app: vxlan-test
  template:
    metadata:
      labels:
        app: vxlan-test
    spec:
      nodeSelector:
        kubernetes.io/os: linux
      tolerations:
        - operator: Exists
      imagePullSecrets:
        - name: aipaas-image-pull-secrets
      affinity:
        nodeAffinity:
          requiredDuringSchedulingIgnoredDuringExecution:
            nodeSelectorTerms:
              - matchExpressions:
                  - key: kubernetes.io/hostname
                    operator: NotIn
                    values:
                      - "xxx"
      containers:
        - name: test
          image: python:3.9.17
          imagePullPolicy: IfNotPresent
          command:
            - /bin/sh
          args:
            - -c
            - python3 -m http.server 8081
          resources:
            limits:
              cpu: 1000m
              memory: 2000Mi
            requests:
              cpu: 1000m
              memory: 2000Mi
          securityContext:
            privileged: true
          env:
            - name: POD_NAME
              valueFrom:
                fieldRef:
                  fieldPath: metadata.name
```

新建的 ds 增加一个 svc

```yaml
---
apiVersion: v1
kind: Service
metadata:
  name: vxlan-test-headless
  labels:
    app: vxlan-test
spec:
  type: ClusterIP
  clusterIP: None
  ports:
    - name: http
      protocol: TCP
      port: 8081
      targetPort: 8081
  selector:
    app: vxlan-test
  
---
apiVersion: v1
kind: Service
metadata:
  name: vxlan-test
  labels:
    app: vxlan-test
spec:
  type: ClusterIP
  ports:
    - name: http
      protocol: TCP
      port: 8081
      targetPort: 8081
  selector:
    app: vxlan-test
```

启动完成后每个节点都会有 pod 存在，并监听 8081 端口

生成一份 ip pod 列表

```bash
oldifs="$IFS"
  
IFS=$'\n'
  
for line in $(kubectl get pod -n bigquant-console -l app=vxlan-test -o wide |grep -v NAME |grep -v none)
do
    pod_ip=$(echo $line|awk '{print $6}')
    pod_node=$(echo $line|awk '{print $7}')
    echo "${pod_node} ${pod_ip}" >> check-vxlan.list
done 
  
IFS="$oldifs"
```

使用如下脚本，在 master 节点探测其他节点是否返回：

```bash
#!/usr/bin/env
  
while read -r line
do
    echo "=="
    pod_ip=$(echo $line|awk '{print $2}')
    pod_node=$(echo $line|awk '{print $1}')
    pod_url="http://$pod_ip:8081"
    echo cheking ... pod_ip ${pod_ip} pod_node ${pod_node}, ${pod_url}
    if curl --connect-timeout 10 -m 20 -sSf "http://${pod_ip}:8081" > /dev/null; then
        echo "${pod_ip} Port is up"
    else
        echo "${pod_ip} Port is down"
    fi
done < /root/check-vxlan.list
```

拷贝到每个节点

```bash
ansible -i hosts all -m copy -a "src=check-vxlan.sh dest=/root/check-vxlan.sh"
ansible -i hosts all -m copy -a "src=check-vxlan.list dest=/root/check-vxlan.list"
```

使用如下的 playbook

```yaml
---
- name: Test VXLan port connectivity between cluster nodes
  hosts: all
  gather_facts: false
  
  tasks:
    - name: Test VXLan port connectivity
      shell: bash /root/check-vxlan.sh
      register: result
      ignore_errors: true
 
    - name: Print command result
      debug:
        var: result.stdout_lines
```

执行并收集结果

```bash
ansible-playbook -i hosts vxlan_test_playbook.yml > vxlan-res.txt
```

测试结果示例

```bash
ok: [10.48.104.45] => {
    "result.stdout_lines": [
        "==",
        "cheking ... pod_ip 100.99.107.36 pod_node node04.xc.bigaiv2.csc.com, http://100.99.107.36:8081",
        "100.99.107.36 Port is up",
        "==",
        "cheking ... pod_ip 100.68.176.149 pod_node inward-node01.xc.bigaiv2.csc.com, http://100.68.176.149:8081",
        "100.68.176.149 Port is up",
        "==",
        "cheking ... pod_ip 100.93.8.146 pod_node master03.xc.bigaiv2.csc.com, http://100.93.8.146:8081",
```

如果出现 down 字样，说明该节点有问题