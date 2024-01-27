## Question 1

Task weight: 1%

You have access to multiple clusters from your main terminal through `kubectl` contexts. Write all those context names into `/opt/course/1/contexts`.

Next write a command to display the current context into `/opt/course/1/context_default_kubectl.sh`, the command should use `kubectl`.

Finally write a second command doing the same thing into `/opt/course/1/context_default_no_kubectl.sh`, but without the use of `kubectl`.

```bash
kubectl config get-contexts -o name > /opt/course/1/contexts

kubectl config current-context

grep "current-context" ~/.kube/config | awk '{print $2}'
```

## Question 2

Task weight: 3%

Use context: `kubectl config use-context k8s-c1-H`

Create a single *Pod* of image `httpd:2.4.41-alpine` in *Namespace* `default`. The *Pod* should be named `pod1` and the container should be named `pod1-container`. This *Pod* should **only** be scheduled on controlplane nodes. Do not add new labels to any nodes.

```bash
kubectl run pod --dry-run=client -o yaml --image=httpd:2.4.41-alpine
```



```yaml
# 2.yaml
apiVersion: v1
kind: Pod
metadata:
  creationTimestamp: null
  labels:
    run: pod1
  name: pod1
spec:
  containers:
  - image: httpd:2.4.41-alpine
    name: pod1-container                       # change
    resources: {}
  dnsPolicy: ClusterFirst
  restartPolicy: Always
  tolerations:                                 # add
  - effect: NoSchedule                         # add
    key: node-role.kubernetes.io/control-plane # add
  nodeSelector:                                # add
    node-role.kubernetes.io/control-plane: ""  # add
status: {}
```

## Question 3

Task weight: 1%

Use context: `kubectl config use-context k8s-c1-H`

There are two *Pods* named `o3db-*` in *Namespace* `project-c13`. C13 management asked you to scale the *Pods* down to one replica to save resources.

```bash
# 确认控制器类型
kubectl get all -n project-c13

# 减少副本
kubectl scale statefulset -n project-c13 o3db --replicas 1
```

## Question 4

Task weight: 4%

Use context: `kubectl config use-context k8s-c1-H`

Do the following in *Namespace* `default`. Create a single *Pod* named `ready-if-service-ready` of image `nginx:1.16.1-alpine`. Configure a LivenessProbe which simply executes command `true`. Also configure a ReadinessProbe which does check if the url `http://service-am-i-ready:80` is reachable, you can use `wget -T2 -O- http://service-am-i-ready:80 `for this. Start the *Pod* and confirm it isn't ready because of the ReadinessProbe.

Create a second *Pod* named `am-i-ready` of image `nginx:1.16.1-alpine` with label `id: cross-server-ready`. The already existing *Service* `service-am-i-ready` should now have that second *Pod* as endpoint.

Now the first *Pod* should be in ready state, confirm that.

```bash
k run ready-if-service-ready --image=nginx:1.16.1-alpine $do > 4_pod1.yaml
k run am-i-ready --image=nginx:1.16.1-alpine --labels="id=cross-server-ready"
```



```yaml
apiVersion: v1
kind: Pod
metadata:
  name: ready-if-service-ready
  namespace: default
spec:
  containers:
  - name: ready-if-service-ready
    image: nginx:1.16.1-alpine
    livenessProbe:
      exec:
        command:
        - "true"
    readinessProbe:
      exec:
        command:
        - wget
        - -T
        - "2"
        - -O
        - "-"
        - http://service-am-i-ready:80
---
apiVersion: v1
kind: Pod
metadata:
  name: am-i-ready
  labels:
    id: cross-server-ready
spec:
  containers:
  - name: am-i-ready
    image: nginx:1.16.1-alpine
    ports:
    - containerPort: 80
```

## Question 5

Task weight: 1%

Use context: `kubectl config use-context k8s-c1-H`

There are various *Pods* in all namespaces. Write a command into `/opt/course/5/find_pods.sh` which lists all *Pods* sorted by their AGE (`metadata.creationTimestamp`).

Write a second command into `/opt/course/5/find_pods_uid.sh` which lists all *Pods* sorted by field `metadata.uid`. Use `kubectl` sorting for both commands.

```bash
kubectl get po -A --sort-by '{metadata.creationTimestamp}'

kubectl get po -A --sort-by '{metadata.uid}'
```

## Question 6

Task weight: 8%

Use context: `kubectl config use-context k8s-c1-H`

Create a new *PersistentVolume* named `safari-pv`. It should have a capacity of *2Gi*, accessMode *ReadWriteOnce*, hostPath `/Volumes/Data` and no storageClassName defined.

Next create a new *PersistentVolumeClaim* in *Namespace* `project-tiger` named `safari-pvc` . It should request *2Gi* storage, accessMode *ReadWriteOnce* and should not define a storageClassName. The *PVC* should bound to the *PV* correctly.

Finally create a new *Deployment* `safari` in *Namespace* `project-tiger` which mounts that volume at `/tmp/safari-data`. The *Pods* of that *Deployment* should be of image `httpd:2.4.41-alpine`.

```yaml
apiVersion: v1
kind: PersistentVolume
metadata:
  name: safari-pv
  labels:
    app: safari
spec:
  capacity:
    storage: 2Gi
  accessModes:
    - ReadWriteOnce
  hostPath:
    path: /Volumes/Data
    
---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: safari-pvc
  namespace: project-tiger
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 2Gi
  selector:
    matchLabels:
      app: safari
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: safari
  namespace: project-tiger
spec:
  replicas: 1
  selector:
    matchLabels:
      app: safari
  template:
    metadata:
      labels:
        app: safari
    spec:
      volumes:
        - name: safari-pvc
          persistentVolumeClaim:
            claimName: safari-pvc
      containers:
      - name: httpd
        image: httpd:2.4.41-alpine
        volumeMounts:
        - mountPath: "/tmp/safari-data"
          name: safari-pvc

```

## Question 7

Task weight: 1%

Use context: `kubectl config use-context k8s-c1-H`

The metrics-server has been installed in the cluster. Your college would like to know the kubectl commands to:

1. show *Nodes* resource usage
2. show *Pods* and their containers resource usage

Please write the commands into `/opt/course/7/node.sh` and `/opt/course/7/pod.sh`.

```bash
kubectl top nodes

kubectl top pods --containers
```

## Question 8

Task weight: 2%

Use context: `kubectl config use-context k8s-c1-H`

Ssh into the controlplane node with `ssh cluster1-controlplane1`. Check how the controlplane components kubelet, kube-apiserver, kube-scheduler, kube-controller-manager and etcd are started/installed on the controlplane node. Also find out the name of the DNS application and how it's started/installed on the controlplane node.

Write your findings into file `/opt/course/8/controlplane-components.txt`. The file should be structured like:

```
# /opt/course/8/controlplane-components.txt
kubelet: [TYPE]
kube-apiserver: [TYPE]
kube-scheduler: [TYPE]
kube-controller-manager: [TYPE]
etcd: [TYPE]
dns: [TYPE] [NAME]
```

Choices of `[TYPE]` are: `not-installed`, `process`, `static-pod`, `pod`

```bash
➜ root@cluster1-controlplane1:~# find /etc/systemd/system/ | grep kube
/etc/systemd/system/kubelet.service.d
/etc/systemd/system/kubelet.service.d/10-kubeadm.conf
/etc/systemd/system/multi-user.target.wants/kubelet.service

➜ root@cluster1-controlplane1:~# find /etc/systemd/system/ | grep etcd

➜ root@cluster1-controlplane1:~# find /etc/kubernetes/manifests/
/etc/kubernetes/manifests/
/etc/kubernetes/manifests/kube-controller-manager.yaml
/etc/kubernetes/manifests/etcd.yaml
/etc/kubernetes/manifests/kube-apiserver.yaml
/etc/kubernetes/manifests/kube-scheduler.yaml
```



```bash
ssh cluster1-controlplane1

# /opt/course/8/controlplane-components.txt
kubelet: process
kube-apiserver: static-pod
kube-scheduler: static-pod
kube-controller-manager: static-pod
etcd: static-pod
dns: pod coredns
```

## Question 9

Task weight: 5%

Use context: `kubectl config use-context k8s-c2-AC`

Ssh into the controlplane node with `ssh cluster2-controlplane1`. **Temporarily** stop the kube-scheduler, this means in a way that you can start it again afterwards.

Create a single *Pod* named `manual-schedule` of image `httpd:2.4-alpine`, confirm it's created but not scheduled on any node.

Now you're the scheduler and have all its power, manually schedule that *Pod* on node cluster2-controlplane1. Make sure it's running.

Start the kube-scheduler again and confirm it's running correctly by creating a second *Pod* named `manual-schedule2` of image `httpd:2.4-alpine` and check if it's running on cluster2-node1.

```bash
ssh cluster2-controlplane1

mv /etc/kubernetes/manifests/kube-scheduler.yaml /root/
```

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: manual-schedule
spec:
  nodeName: cluster2-controlplane1
  containers:
  - name: httpd
    image: httpd:2.4-alpine

---
apiVersion: v1
kind: Pod
metadata:
  name: manual-schedule2
spec:
  containers:
  - name: httpd
    image: httpd:2.4-alpine
```

## Question 10

Task weight: 6%

Use context: `kubectl config use-context k8s-c1-H`

Create a new *ServiceAccount* `processor` in *Namespace* `project-hamster`. Create a *Role* and *RoleBinding*, both named `processor` as well. These should allow the new *SA* to only create *Secrets* and *ConfigMaps* in that *Namespace*.

```bash
kubectl create role processor -n project-hamster --verb=create --resource=secrets,configmaps
kubectl create sa processor -n project-hamster
kubectl create rolebinding processor --role=processor --serviceaccount=project-hamster:processor --namespace=project-hamster
```

## Question 11

Task weight: 4%

Use context: `kubectl config use-context k8s-c1-H`

Use *Namespace* `project-tiger` for the following. Create a *DaemonSet* named `ds-important` with image `httpd:2.4-alpine` and labels `id=ds-important` and `uuid=18426a0b-5f59-4e10-923f-c0e078e82462`. The *Pods* it creates should request 10 millicore cpu and 10 mebibyte memory. The *Pods* of that *DaemonSet* should run on all nodes, also controlplanes.

```bash
k -n project-tiger create deployment --image=httpd:2.4-alpine ds-important $do > 11.yaml
```



```yaml
apiVersion: apps/v1
kind: DaemonSet
metadata:
  name: ds-important
  namespace: project-tiger
  labels:
    id: ds-important
    uuid: 18426a0b-5f59-4e10-923f-c0e078e82462
spec:
  selector:
    matchLabels:
      id: ds-important
      uuid: 18426a0b-5f59-4e10-923f-c0e078e82462
  template:
    metadata:
      labels:
        id: ds-important
        uuid: 18426a0b-5f59-4e10-923f-c0e078e82462
    spec:
      tolerations:
      - key: node-role.kubernetes.io/control-plane
        operator: Exists
        effect: NoSchedule
      - key: node-role.kubernetes.io/master
        operator: Exists
        effect: NoSchedule
      containers:
      - name: httpd
        image: httpd:2.4-alpine
        resources:
          requests:
            cpu: 10m
            memory: 10Mi

```

## Question 12

Task weight: 6%

Use context: `kubectl config use-context k8s-c1-H`

Use *Namespace* `project-tiger` for the following. Create a *Deployment* named `deploy-important` with label `id=very-important` (the `Pods` should also have this label) and 3 replicas. It should contain two containers, the first named `container1` with image `nginx:1.17.6-alpine` and the second one named container2 with image `google/pause`.

There should be only ever **one** *Pod* of that *Deployment* running on **one** worker node. We have two worker nodes: `cluster1-node1` and `cluster1-node2`. Because the *Deployment* has three replicas the result should be that on both nodes **one** *Pod* is running. The third *Pod* won't be scheduled, unless a new worker node will be added.

In a way we kind of simulate the behaviour of a *DaemonSet* here, but using a *Deployment* and a fixed number of replicas.

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: deploy-important
  namespace: project-tiger
  labels:
    id: very-important
spec:
  replicas: 3
  selector:
    matchLabels:
      id: very-important
  template:
    metadata:
      labels:
        id: very-important
    spec:
      affinity:
        podAntiAffinity:
          requiredDuringSchedulingIgnoredDuringExecution:
            - labelSelector:
                matchExpressions:
                - key: id
                  operator: In
                  values:
                  - very-important
              topologyKey: "kubernetes.io/hostname"
      containers:
      - name: container1
        image: nginx:1.17.6-alpine
      - name: container2
        image: google/pause
```

## Question 13

*Task weight: 4%*

Use context: `kubectl config use-context k8s-c1-H`

Create a *Pod* named `multi-container-playground` in *Namespace* `default` with three containers, named `c1`, `c2` and `c3`. There should be a volume attached to that *Pod* and mounted into every container, but the volume shouldn't be persisted or shared with other *Pods*.

Container `c1` should be of image `nginx:1.17.6-alpine` and have the name of the node where its *Pod* is running available as environment variable MY_NODE_NAME.

Container `c2` should be of image `busybox:1.31.1` and write the output of the `date` command every second in the shared volume into file `date.log`. You can use `while true; do date >> /your/vol/path/date.log; sleep 1; done` for this.

Container `c3` should be of image `busybox:1.31.1` and constantly send the content of file `date.log` from the shared volume to stdout. You can use `tail -f /your/vol/path/date.log` for this.

Check the logs of container `c3` to confirm correct setup.

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: multi-container-playground
  namespace: default
spec:
  volumes:
  - name: cache-volume
    emptyDir: {}
  containers:
  - name: c1
    image: nginx:1.17.6-alpine
    volumeMounts:
    - mountPath: /your/vol/path
      name: cache-volume
    env:
    - name: MY_NODE_NAME
      valueFrom:
        fieldRef:
          fieldPath: spec.nodeName
  - name: c2
    image: busybox:1.31.1
    volumeMounts:
    - mountPath: /your/vol/path
      name: cache-volume
    command:
    - /bin/sh
    - -c
    - while true; do date >> /your/vol/path/date.log; sleep 1; done
  - name: c3
    image: busybox:1.31.1
    volumeMounts:
    - mountPath: /your/vol/path
      name: cache-volume
    command:
    - tail
    - -f
    - /your/vol/path/date.log
```

## Question 14

Task weight: 2%

Use context: `kubectl config use-context k8s-c1-H`

You're ask to find out following information about the cluster `k8s-c1-H `:

1. How many controlplane nodes are available?
2. How many worker nodes are available?
3. What is the Service CIDR?
4. Which Networking (or CNI Plugin) is configured and where is its config file?
5. Which suffix will static pods have that run on cluster1-node1?

Write your answers into file `/opt/course/14/cluster-info`, structured like this:

```
# /opt/course/14/cluster-info
1: [ANSWER]
2: [ANSWER]
3: [ANSWER]
4: [ANSWER]
5: [ANSWER]
```

```bash
> kubectl get nodes |grep control-plane
> kubectl get nodes |grep -v control-plane
> kubectl cluster-info dump | grep service-cluster-ip-range

# /opt/course/14/cluster-info
1: 1
2: 2
3: 10.96.0.0/12
4: weave, /etc/cni/net.d/10-weave.conflist
5: -cluster1-node1
```

## Question 15

*Task weight: 3%*

Use context: `kubectl config use-context k8s-c2-AC`

Write a command into `/opt/course/15/cluster_events.sh` which shows the latest events in the whole cluster, ordered by time (`metadata.creationTimestamp`). Use `kubectl` for it.

Now delete the kube-proxy *Pod* running on node cluster2-node1 and write the events this caused into `/opt/course/15/pod_kill.log`.

Finally kill the containerd container of the kube-proxy *Pod* on node cluster2-node1 and write the events into `/opt/course/15/container_kill.log`.

Do you notice differences in the events both actions caused?

```bash
kubectl get events --sort-by '{metadata.creationTimestamp}'

k -n kube-system get pod -o wide | grep proxy # find pod running on cluster2-node1
k -n kube-system delete pod kube-proxy-z64cg

ctr -n k8s.io c ls |grep kube-proxy
ctr -n k8s.io t kill -s SIGKILL 8da78b4b69a068f5830a8398a374e865f3e32b8f7dba2e41d4be09bdad217bd4
ctr -n k8s.io task rm 8da78b4b69a068f5830a8398a374e865f3e32b8f7dba2e41d4be09bdad217bd4
ctr -n k8s.io snapshots rm 8da78b4b69a068f5830a8398a374e865f3e32b8f7dba2e41d4be09bdad217bd4
ctr -n k8s.io container rm 8da78b4b69a068f5830a8398a374e865f3e32b8f7dba2e41d4be09bdad217bd4
```

## Question 16

*Task weight: 2%*

Use context: `kubectl config use-context k8s-c1-H`

Write the names of all namespaced Kubernetes resources (like *Pod*, *Secret*, *ConfigMap*...) into `/opt/course/16/resources.txt`.

Find the `project-*` *Namespace* with the highest number of `Roles` defined in it and write its name and amount of *Roles* into `/opt/course/16/crowded-namespace.txt`.

```bash
k api-resources    # shows all

k api-resources -h # help always good

k api-resources --namespaced -o name > /opt/course/16/resources.txt


➜ k -n project-c13 get role --no-headers | wc -l
No resources found in project-c13 namespace.
0

➜ k -n project-c14 get role --no-headers | wc -l
300

➜ k -n project-hamster get role --no-headers | wc -l
No resources found in project-hamster namespace.
0

➜ k -n project-snake get role --no-headers | wc -l
No resources found in project-snake namespace.
0

➜ k -n project-tiger get role --no-headers | wc -l
No resources found in project-tiger namespace.
0

# /opt/course/16/crowded-namespace.txt
project-c14 with 300 resources
```

## Question 17

*Task weight: 3%*

Use context: `kubectl config use-context k8s-c1-H`

In *Namespace* `project-tiger` create a *Pod* named `tigers-reunite` of image `httpd:2.4.41-alpine` with labels `pod=container` and `container=pod`. Find out on which node the *Pod* is scheduled. Ssh into that node and find the containerd container belonging to that *Pod*.

Using command `crictl`:

1. Write the ID of the container and the `info.runtimeType` into `/opt/course/17/pod-container.txt`
2. Write the logs of the container into `/opt/course/17/pod-container.log`

```bash
k -n project-tiger run tigers-reunite \
  --image=httpd:2.4.41-alpine \
  --labels "pod=container,container=pod"
  
➜ ssh cluster1-node2

➜ root@cluster1-node2:~# crictl ps | grep tigers-reunite
b01edbe6f89ed    54b0995a63052    5 seconds ago    Running        tigers-reunite ...

➜ root@cluster1-node2:~# crictl inspect b01edbe6f89ed | grep runtimeType
    "runtimeType": "io.containerd.runc.v2",
```

## Question 18

*Task weight: 8%*

Use context: `kubectl config use-context k8s-c3-CCC`

There seems to be an issue with the kubelet not running on `cluster3-node1`. Fix it and confirm that cluster has node `cluster3-node1` available in Ready state afterwards. You should be able to schedule a *Pod* on `cluster3-node1` afterwards.

Write the reason of the issue into `/opt/course/18/reason.txt`.

```bash
# /opt/course/18/reason.txt
wrong path to kubelet binary specified in service config
```

## Question 19

*Task weight: 3%*

> **NOTE:** This task can only be solved if questions 18 or 20 have been successfully implemented and the k8s-c3-CCC cluster has a functioning worker node

Use context: `kubectl config use-context k8s-c3-CCC`

Do the following in a new *Namespace* `secret`. Create a *Pod* named `secret-pod` of image `busybox:1.31.1` which should keep running for some time.

There is an existing *Secret* located at `/opt/course/19/secret1.yaml`, create it in the *Namespace* `secret` and mount it readonly into the *Pod* at `/tmp/secret1`.

Create a new *Secret* in *Namespace* `secret` called `secret2` which should contain `user=user1` and `pass=1234`. These entries should be available inside the *Pod's* container as environment variables APP_USER and APP_PASS.

Confirm everything is working.

```bash
k -n secret create secret generic secret2 --from-literal=user=user1 --from-literal=pass=1234

k -n secret run secret-pod --image=busybox:1.31.1 $do -- sh -c "sleep 5d" > 19.yaml

```

## Question 20

*Task weight: 10%*

Use context: `kubectl config use-context k8s-c3-CCC`

Your coworker said node `cluster3-node2` is running an older Kubernetes version and is not even part of the cluster. Update Kubernetes on that node to the exact version that's running on `cluster3-controlplane1`. Then add this node to the cluster. Use kubeadm for this.

Answer:

Upgrade Kubernetes to cluster3-controlplane1 version

Search in the docs for kubeadm upgrade: https://kubernetes.io/docs/tasks/administer-cluster/kubeadm/kubeadm-upgrade

```
➜ k get node
NAME                     STATUS   ROLES           AGE   VERSION
cluster3-controlplane1   Ready    control-plane   22h   v1.28.2
cluster3-node1           Ready    <none>          22h   v1.28.2
```

Controlplane node seems to be running Kubernetes 1.28.2. Node `cluster3-node2` might not yet be part of the cluster depending on previous tasks.

```
➜ ssh cluster3-node2


➜ root@cluster3-node2:~# kubeadm version
kubeadm version: &version.Info{Major:"1", Minor:"27", GitVersion:"v1.27.4", GitCommit:"fa3d7990104d7c1f16943a67f11b154b71f6a132", GitTreeState:"clean", BuildDate:"2023-07-19T12:19:40Z", GoVersion:"go1.20.6", Compiler:"gc", Platform:"linux/amd64"}


➜ root@cluster3-node2:~# kubectl version --short
Flag --short has been deprecated, and will be removed in the future. The --short output will become the default.
Client Version: v1.27.4
Kustomize Version: v5.0.1
The connection to the server localhost:8080 was refused - did you specify the right host or port?


➜ root@cluster3-node2:~# kubelet --version
Kubernetes v1.27.4
```

Here kubeadm is already installed in the wanted version, so we don't need to install it. Hence we can run:

```
➜ root@cluster3-node2:~# kubeadm upgrade node
couldn't create a Kubernetes client from file "/etc/kubernetes/kubelet.conf": failed to load admin kubeconfig: open /etc/kubernetes/kubelet.conf: no such file or directory
To see the stack trace of this error execute with --v=5 or higher
```

This is usually the proper command to upgrade a node. But this error means that this node was never even initialised, so nothing to update here. This will be done later using `kubeadm join`. For now we can continue with kubelet and kubectl:

```
➜ root@cluster3-node2:~# apt update
Hit:1 http://ppa.launchpad.net/rmescandon/yq/ubuntu focal InRelease
Get:2 http://security.ubuntu.com/ubuntu focal-security InRelease [114 kB]                        
Hit:4 http://us.archive.ubuntu.com/ubuntu focal InRelease                                         
Get:3 https://packages.cloud.google.com/apt kubernetes-xenial InRelease [8,993 B]
Get:5 http://us.archive.ubuntu.com/ubuntu focal-updates InRelease [114 kB]
Get:6 http://us.archive.ubuntu.com/ubuntu focal-backports InRelease [108 kB]
Get:7 http://us.archive.ubuntu.com/ubuntu focal-updates/main amd64 Packages [2,851 kB]
Get:8 http://us.archive.ubuntu.com/ubuntu focal-updates/main i386 Packages [884 kB]
Get:9 http://us.archive.ubuntu.com/ubuntu focal-updates/universe amd64 Packages [1,117 kB]
Get:10 http://us.archive.ubuntu.com/ubuntu focal-updates/universe i386 Packages [748 kB]
Fetched 5,946 kB in 3s (2,063 kB/s)                       
Reading package lists... Done
Building dependency tree       
Reading state information... Done
217 packages can be upgraded. Run 'apt list --upgradable' to see them.


➜ root@cluster3-node2:~# apt show kubectl -a | grep 1.28
...
Version: 1.28.2-00
Version: 1.28.1-00
Version: 1.28.0-00


➜ root@cluster3-node2:~# apt install kubectl=1.28.2-00 kubelet=1.28.2-00
...
Fetched 29.1 MB in 4s (7,547 kB/s)  
(Reading database ... 112527 files and directories currently installed.)
Preparing to unpack .../kubectl_1.28.2-00_amd64.deb ...
Unpacking kubectl (1.28.2-00) over (1.27.4-00) ...
dpkg: warning: downgrading kubelet from 1.27.4-00 to 1.28.2-00
Preparing to unpack .../kubelet_1.28.2-00_amd64.deb ...
Unpacking kubelet (1.28.2-00) over (1.27.4-00) ...
Setting up kubectl (1.28.2-00) ...
Setting up kubelet (1.28.2-00) ...


➜ root@cluster3-node2:~# kubelet --version
Kubernetes v1.28.2
```

Now we're up to date with kubeadm, kubectl and kubelet. Restart the kubelet:

```
➜ root@cluster3-node2:~# service kubelet restart


➜ root@cluster3-node2:~# service kubelet status
● kubelet.service - kubelet: The Kubernetes Node Agent
     Loaded: loaded (/lib/systemd/system/kubelet.service; enabled; vendor preset: enabled)
    Drop-In: /etc/systemd/system/kubelet.service.d
             └─10-kubeadm.conf
     Active: activating (auto-restart) (Result: exit-code) since Fri 2023-09-22 14:37:37 UTC; 2s a>
       Docs: https://kubernetes.io/docs/home/
    Process: 34331 ExecStart=/usr/bin/kubelet $KUBELET_KUBECONFIG_ARGS $KUBELET_CONFIG_ARGS $KUBEL>
   Main PID: 34331 (code=exited, status=1/FAILURE)


Sep 22 14:37:37 cluster3-node2 systemd[1]: kubelet.service: Main process exited, code=exited, stat>
Sep 22 14:37:37 cluster3-node2 systemd[1]: kubelet.service: Failed with result 'exit-code'.
```

These errors occur because we still need to run `kubeadm join` to join the node into the cluster. Let's do this in the next step.

 

Add cluster3-node2 to cluster

First we log into the controlplane1 and generate a new TLS bootstrap token, also printing out the join command:

```
➜ ssh cluster3-controlplane1


➜ root@cluster3-controlplane1:~# kubeadm token create --print-join-command
kubeadm join 192.168.100.31:6443 --token lyl4o0.vbkmv9rdph5qd660 --discovery-token-ca-cert-hash sha256:b0c94ccf935e27306ff24bce4b8f611c621509e80075105b3f25d296a94927ce 


➜ root@cluster3-controlplane1:~# kubeadm token list
TOKEN                     TTL         EXPIRES                ...
lyl4o0.vbkmv9rdph5qd660   23h         2023-09-23T14:38:12Z   ...
n4dkqj.hu52l46jfo4he61e   <forever>   <never>                ...
s7cmex.ty1olulkuljju9am   18h         2023-09-23T09:34:20Z   ...
```

We see the expiration of 23h for our token, we could adjust this by passing the ttl argument.

Next we connect again to `cluster3-node2` and simply execute the join command:

```
➜ ssh cluster3-node2


➜ root@cluster3-node2:~# kubeadm join 192.168.100.31:6443 --token lyl4o0.vbkmv9rdph5qd660 --discovery-token-ca-cert-hash sha256:b0c94ccf935e27306ff24bce4b8f611c621509e80075105b3f25d296a94927ce 


[preflight] Running pre-flight checks
[preflight] Reading configuration from the cluster...
[preflight] FYI: You can look at this config file with 'kubectl -n kube-system get cm kubeadm-config -o yaml'
W0922 14:39:56.786605   34648 configset.go:177] error unmarshaling configuration schema.GroupVersionKind{Group:"kubeproxy.config.k8s.io", Version:"v1alpha1", Kind:"KubeProxyConfiguration"}: strict decoding error: unknown field "logging"
[kubelet-start] Writing kubelet configuration to file "/var/lib/kubelet/config.yaml"
[kubelet-start] Writing kubelet environment file with flags to file "/var/lib/kubelet/kubeadm-flags.env"
[kubelet-start] Starting the kubelet
[kubelet-start] Waiting for the kubelet to perform the TLS Bootstrap...


This node has joined the cluster:
* Certificate signing request was sent to apiserver and a response was received.
* The Kubelet was informed of the new secure connection details.


Run 'kubectl get nodes' on the control-plane to see this node join the cluster.




➜ root@cluster3-node2:~# service kubelet status
● kubelet.service - kubelet: The Kubernetes Node Agent
     Loaded: loaded (/lib/systemd/system/kubelet.service; enabled; vendor preset: enabled)
    Drop-In: /etc/systemd/system/kubelet.service.d
             └─10-kubeadm.conf
     Active: active (running) since Fri 2023-09-22 14:39:57 UTC; 14s ago
       Docs: https://kubernetes.io/docs/home/
   Main PID: 34695 (kubelet)
      Tasks: 12 (limit: 462)
     Memory: 55.4M
...
```

If you have troubles with `kubeadm join` you might need to run `kubeadm reset`.

This looks great though for us. Finally we head back to the main terminal and check the node status:

```
➜ k get node
NAME                     STATUS     ROLES           AGE    VERSION
cluster3-controlplane1   Ready      control-plane   102m   v1.28.2
cluster3-node1           Ready      <none>          97m    v1.28.2
cluster3-node2           NotReady   <none>          108s   v1.28.2
```

Give it a bit of time till the node is ready.

```
➜ k get node
NAME                     STATUS     ROLES           AGE    VERSION
cluster3-controlplane1   Ready      control-plane   102m   v1.28.2
cluster3-node1           Ready      <none>          97m    v1.28.2
cluster3-node2           Ready      <none>          108s   v1.28.2
```

We see `cluster3-node2` is now available and up to date.

## Question 21

*Task weight: 2%*

Use context: `kubectl config use-context k8s-c3-CCC`

Create a `Static Pod` named `my-static-pod` in *Namespace* `default` on cluster3-controlplane1. It should be of image `nginx:1.16-alpine` and have resource requests for `10m` CPU and `20Mi` memory.

Then create a NodePort *Service* named `static-pod-service` which exposes that static *Pod* on port 80 and check if it has *Endpoints* and if it's reachable through the `cluster3-controlplane1` internal IP address. You can connect to the internal node IPs from your main terminal.

Answer:

```
➜ ssh cluster3-controlplane1


➜ root@cluster1-controlplane1:~# cd /etc/kubernetes/manifests/


➜ root@cluster1-controlplane1:~# kubectl run my-static-pod \
    --image=nginx:1.16-alpine \
    -o yaml --dry-run=client > my-static-pod.yaml
```

Then edit the `my-static-pod.yaml` to add the requested resource requests:

```
# /etc/kubernetes/manifests/my-static-pod.yaml
apiVersion: v1
kind: Pod
metadata:
  creationTimestamp: null
  labels:
    run: my-static-pod
  name: my-static-pod
spec:
  containers:
  - image: nginx:1.16-alpine
    name: my-static-pod
    resources:
      requests:
        cpu: 10m
        memory: 20Mi
  dnsPolicy: ClusterFirst
  restartPolicy: Always
status: {}
```

 

And make sure it's running:

```
➜ k get pod -A | grep my-static
NAMESPACE     NAME                                   READY   STATUS   ...   AGE
default       my-static-pod-cluster3-controlplane1   1/1     Running  ...   22s
```

Now we expose that static *Pod*:

```
k expose pod my-static-pod-cluster3-controlplane1 \
  --name static-pod-service \
  --type=NodePort \
  --port 80
```

This would generate a *Service* like:

```
# kubectl expose pod my-static-pod-cluster3-controlplane1 --name static-pod-service --type=NodePort --port 80
apiVersion: v1
kind: Service
metadata:
  creationTimestamp: null
  labels:
    run: my-static-pod
  name: static-pod-service
spec:
  ports:
  - port: 80
    protocol: TCP
    targetPort: 80
  selector:
    run: my-static-pod
  type: NodePort
status:
  loadBalancer: {}
```

Then run and test:

```
➜ k get svc,ep -l run=my-static-pod
NAME                         TYPE       CLUSTER-IP      EXTERNAL-IP   PORT(S)        AGE
service/static-pod-service   NodePort   10.99.168.252   <none>        80:30352/TCP   30s


NAME                           ENDPOINTS      AGE
endpoints/static-pod-service   10.32.0.4:80   30s
```

Looking good.

## Question 22

*Task weight: 2%*

Use context: `kubectl config use-context k8s-c2-AC`

Check how long the kube-apiserver server certificate is valid on `cluster2-controlplane1`. Do this with openssl or cfssl. Write the exipiration date into `/opt/course/22/expiration`.

Also run the correct `kubeadm` command to list the expiration dates and confirm both methods show the same date.

Write the correct `kubeadm` command that would renew the apiserver server certificate into `/opt/course/22/kubeadm-renew-certs.sh`.

Answer:

First let's find that certificate:

```
➜ ssh cluster2-controlplane1


➜ root@cluster2-controlplane1:~# find /etc/kubernetes/pki | grep apiserver
/etc/kubernetes/pki/apiserver.crt
/etc/kubernetes/pki/apiserver-etcd-client.crt
/etc/kubernetes/pki/apiserver-etcd-client.key
/etc/kubernetes/pki/apiserver-kubelet-client.crt
/etc/kubernetes/pki/apiserver.key
/etc/kubernetes/pki/apiserver-kubelet-client.key
```

Next we use openssl to find out the expiration date:

```
➜ root@cluster2-controlplane1:~# openssl x509  -noout -text -in /etc/kubernetes/pki/apiserver.crt | grep Validity -A2
        Validity
            Not Before: Dec 20 18:05:20 2022 GMT
            Not After : Dec 20 18:05:20 2023 GMT
```

There we have it, so we write it in the required location on our main terminal:

```
# /opt/course/22/expiration
Dec 20 18:05:20 2023 GMT
```

And we use the feature from kubeadm to get the expiration too:

```
➜ root@cluster2-controlplane1:~# kubeadm certs check-expiration | grep apiserver
apiserver                Jan 14, 2022 18:49 UTC   363d        ca               no      
apiserver-etcd-client    Jan 14, 2022 18:49 UTC   363d        etcd-ca          no      
apiserver-kubelet-client Jan 14, 2022 18:49 UTC   363d        ca               no 
```

Looking good. And finally we write the command that would renew all certificates into the requested location:

```
# /opt/course/22/kubeadm-renew-certs.sh
kubeadm certs renew apiserver
```

## Question 23

*Task weight: 2%*

Use context: `kubectl config use-context k8s-c2-AC`

Node cluster2-node1 has been added to the cluster using `kubeadm` and TLS bootstrapping.

Find the "Issuer" and "Extended Key Usage" values of the cluster2-node1:

1. kubelet **client** certificate, the one used for outgoing connections to the kube-apiserver.
2. kubelet **server** certificate, the one used for incoming connections from the kube-apiserver.

Write the information into file `/opt/course/23/certificate-info.txt`.

Compare the "Issuer" and "Extended Key Usage" fields of both certificates and make sense of these.

Answer:

To find the correct kubelet certificate directory, we can look for the default value of the `--cert-dir` parameter for the kubelet. For this search for "kubelet" in the Kubernetes docs which will lead to: https://kubernetes.io/docs/reference/command-line-tools-reference/kubelet. We can check if another certificate directory has been configured using `ps aux` or in `/etc/systemd/system/kubelet.service.d/10-kubeadm.conf`.

First we check the kubelet client certificate:

```
➜ ssh cluster2-node1


➜ root@cluster2-node1:~# openssl x509  -noout -text -in /var/lib/kubelet/pki/kubelet-client-current.pem | grep Issuer
        Issuer: CN = kubernetes
        
➜ root@cluster2-node1:~# openssl x509  -noout -text -in /var/lib/kubelet/pki/kubelet-client-current.pem | grep "Extended Key Usage" -A1
            X509v3 Extended Key Usage: 
                TLS Web Client Authentication
```

Next we check the kubelet server certificate:

```
➜ root@cluster2-node1:~# openssl x509  -noout -text -in /var/lib/kubelet/pki/kubelet.crt | grep Issuer
          Issuer: CN = cluster2-node1-ca@1588186506


➜ root@cluster2-node1:~# openssl x509  -noout -text -in /var/lib/kubelet/pki/kubelet.crt | grep "Extended Key Usage" -A1
            X509v3 Extended Key Usage: 
                TLS Web Server Authentication
```

We see that the server certificate was generated on the worker node itself and the client certificate was issued by the Kubernetes api. The "Extended Key Usage" also shows if it's for client or server authentication.

More about this: https://kubernetes.io/docs/reference/command-line-tools-reference/kubelet-tls-bootstrapping

## Question 24

*Task weight: 9%*

Use context: `kubectl config use-context k8s-c1-H`

There was a security incident where an intruder was able to access the whole cluster from a single hacked backend *Pod*.

To prevent this create a *NetworkPolicy* called `np-backend` in *Namespace* `project-snake`. It should allow the `backend-*` *Pods* only to:

- connect to `db1-*` *Pods* on port 1111
- connect to `db2-*` *Pods* on port 2222

Use the `app` label of *Pods* in your policy.

After implementation, connections from `backend-*` *Pods* to `vault-*` *Pods* on port 3333 should for example no longer work.

Answer:

First we look at the existing *Pods* and their labels:

```
➜ k -n project-snake get pod
NAME        READY   STATUS    RESTARTS   AGE
backend-0   1/1     Running   0          8s
db1-0       1/1     Running   0          8s
db2-0       1/1     Running   0          10s
vault-0     1/1     Running   0          10s


➜ k -n project-snake get pod -L app
NAME        READY   STATUS    RESTARTS   AGE     APP
backend-0   1/1     Running   0          3m15s   backend
db1-0       1/1     Running   0          3m15s   db1
db2-0       1/1     Running   0          3m17s   db2
vault-0     1/1     Running   0          3m17s   vault
```

We test the current connection situation and see nothing is restricted:

```
➜ k -n project-snake get pod -o wide
NAME        READY   STATUS    RESTARTS   AGE     IP          ...
backend-0   1/1     Running   0          4m14s   10.44.0.24  ...
db1-0       1/1     Running   0          4m14s   10.44.0.25  ...
db2-0       1/1     Running   0          4m16s   10.44.0.23  ...
vault-0     1/1     Running   0          4m16s   10.44.0.22  ...


➜ k -n project-snake exec backend-0 -- curl -s 10.44.0.25:1111
database one


➜ k -n project-snake exec backend-0 -- curl -s 10.44.0.23:2222
database two


➜ k -n project-snake exec backend-0 -- curl -s 10.44.0.22:3333
vault secret storage
```

Now we create the *NP* by copying and chaning an example from the k8s docs:

```yaml
vim 24_np.yaml
# 24_np.yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: np-backend
  namespace: project-snake
spec:
  podSelector:
    matchLabels:
      app: backend
  policyTypes:
    - Egress                    # policy is only about Egress
  egress:
    -                           # first rule
      to:                           # first condition "to"
      - podSelector:
          matchLabels:
            app: db1
      ports:                        # second condition "port"
      - protocol: TCP
        port: 1111
    -                           # second rule
      to:                           # first condition "to"
      - podSelector:
          matchLabels:
            app: db2
      ports:                        # second condition "port"
      - protocol: TCP
        port: 2222
```

The *NP* above has two rules with two conditions each, it can be read as:

```
allow outgoing traffic if:
  (destination pod has label app=db1 AND port is 1111)
  OR
  (destination pod has label app=db2 AND port is 2222)
```

## Question 25

*Task weight: 8%*

Use context: `kubectl config use-context k8s-c3-CCC`

Make a backup of etcd running on cluster3-controlplane1 and save it on the controlplane node at `/tmp/etcd-backup.db`.

Then create any kind of *Pod* in the cluster.

Finally restore the backup, confirm the cluster is still working and that the created *Pod* is no longer with us.

Answer:

Etcd Backup

First we log into the controlplane and try to create a snapshop of etcd:

```
➜ ssh cluster3-controlplane1


➜ root@cluster3-controlplane1:~# ETCDCTL_API=3 etcdctl snapshot save /tmp/etcd-backup.db
Error:  rpc error: code = Unavailable desc = transport is closing
```

But it fails because we need to authenticate ourselves. For the necessary information we can check the etc manifest:

```
➜ root@cluster3-controlplane1:~# vim /etc/kubernetes/manifests/etcd.yaml
```

We only check the `etcd.yaml` for necessary information we don't change it.

```
# /etc/kubernetes/manifests/etcd.yaml
apiVersion: v1
kind: Pod
metadata:
  creationTimestamp: null
  labels:
    component: etcd
    tier: control-plane
  name: etcd
  namespace: kube-system
spec:
  containers:
  - command:
    - etcd
    - --advertise-client-urls=https://192.168.100.31:2379
    - --cert-file=/etc/kubernetes/pki/etcd/server.crt                           # use
    - --client-cert-auth=true
    - --data-dir=/var/lib/etcd
    - --initial-advertise-peer-urls=https://192.168.100.31:2380
    - --initial-cluster=cluster3-controlplane1=https://192.168.100.31:2380
    - --key-file=/etc/kubernetes/pki/etcd/server.key                            # use
    - --listen-client-urls=https://127.0.0.1:2379,https://192.168.100.31:2379   # use
    - --listen-metrics-urls=http://127.0.0.1:2381
    - --listen-peer-urls=https://192.168.100.31:2380
    - --name=cluster3-controlplane1
    - --peer-cert-file=/etc/kubernetes/pki/etcd/peer.crt
    - --peer-client-cert-auth=true
    - --peer-key-file=/etc/kubernetes/pki/etcd/peer.key
    - --peer-trusted-ca-file=/etc/kubernetes/pki/etcd/ca.crt                    # use
    - --snapshot-count=10000
    - --trusted-ca-file=/etc/kubernetes/pki/etcd/ca.crt
    image: k8s.gcr.io/etcd:3.3.15-0
    imagePullPolicy: IfNotPresent
    livenessProbe:
      failureThreshold: 8
      httpGet:
        host: 127.0.0.1
        path: /health
        port: 2381
        scheme: HTTP
      initialDelaySeconds: 15
      timeoutSeconds: 15
    name: etcd
    resources: {}
    volumeMounts:
    - mountPath: /var/lib/etcd
      name: etcd-data
    - mountPath: /etc/kubernetes/pki/etcd
      name: etcd-certs
  hostNetwork: true
  priorityClassName: system-cluster-critical
  volumes:
  - hostPath:
      path: /etc/kubernetes/pki/etcd
      type: DirectoryOrCreate
    name: etcd-certs
  - hostPath:
      path: /var/lib/etcd                                                     # important
      type: DirectoryOrCreate
    name: etcd-data
status: {}
```

But we also know that the api-server is connecting to etcd, so we can check how its manifest is configured:

```
➜ root@cluster3-controlplane1:~# cat /etc/kubernetes/manifests/kube-apiserver.yaml | grep etcd
    - --etcd-cafile=/etc/kubernetes/pki/etcd/ca.crt
    - --etcd-certfile=/etc/kubernetes/pki/apiserver-etcd-client.crt
    - --etcd-keyfile=/etc/kubernetes/pki/apiserver-etcd-client.key
    - --etcd-servers=https://127.0.0.1:2379
```

We use the authentication information and pass it to etcdctl:

```
➜ root@cluster3-controlplane1:~# ETCDCTL_API=3 etcdctl snapshot save /tmp/etcd-backup.db \
--cacert /etc/kubernetes/pki/etcd/ca.crt \
--cert /etc/kubernetes/pki/etcd/server.crt \
--key /etc/kubernetes/pki/etcd/server.key


Snapshot saved at /tmp/etcd-backup.db
```

 

> **NOTE:** Dont use `snapshot status` because it can alter the snapshot file and render it invalid

 

Etcd restore

Now create a *Pod* in the cluster and wait for it to be running:

```
➜ root@cluster3-controlplane1:~# kubectl run test --image=nginx
pod/test created


➜ root@cluster3-controlplane1:~# kubectl get pod -l run=test -w
NAME   READY   STATUS    RESTARTS   AGE
test   1/1     Running   0          60s
```



> **NOTE:** If you didn't solve questions 18 or 20 and cluster3 doesn't have a ready worker node then the created pod might stay in a Pending state. This is still ok for this task.



Next we stop all controlplane components:

```
root@cluster3-controlplane1:~# cd /etc/kubernetes/manifests/


root@cluster3-controlplane1:/etc/kubernetes/manifests# mv * ..


root@cluster3-controlplane1:/etc/kubernetes/manifests# watch crictl ps
```

Now we restore the snapshot into a specific directory:

```
➜ root@cluster3-controlplane1:~# ETCDCTL_API=3 etcdctl snapshot restore /tmp/etcd-backup.db \
--data-dir /var/lib/etcd-backup \
--cacert /etc/kubernetes/pki/etcd/ca.crt \
--cert /etc/kubernetes/pki/etcd/server.crt \
--key /etc/kubernetes/pki/etcd/server.key


2020-09-04 16:50:19.650804 I | mvcc: restore compact to 9935
2020-09-04 16:50:19.659095 I | etcdserver/membership: added member 8e9e05c52164694d [http://localhost:2380] to cluster cdf818194e3a8c32
```

We could specify another host to make the backup from by using `etcdctl --endpoints http://IP`, but here we just use the default value which is: `http://127.0.0.1:2379,http://127.0.0.1:4001`.

The restored files are located at the new folder `/var/lib/etcd-backup`, now we have to tell etcd to use that directory:

```
➜ root@cluster3-controlplane1:~# vim /etc/kubernetes/etcd.yaml
# /etc/kubernetes/etcd.yaml
apiVersion: v1
kind: Pod
metadata:
  creationTimestamp: null
  labels:
    component: etcd
    tier: control-plane
  name: etcd
  namespace: kube-system
spec:
...
    - mountPath: /etc/kubernetes/pki/etcd
      name: etcd-certs
  hostNetwork: true
  priorityClassName: system-cluster-critical
  volumes:
  - hostPath:
      path: /etc/kubernetes/pki/etcd
      type: DirectoryOrCreate
    name: etcd-certs
  - hostPath:
      path: /var/lib/etcd-backup                # change
      type: DirectoryOrCreate
    name: etcd-data
status: {}
```

Now we move all controlplane yaml again into the manifest directory. Give it some time (up to several minutes) for etcd to restart and for the api-server to be reachable again:

```
root@cluster3-controlplane1:/etc/kubernetes/manifests# mv ../*.yaml .


root@cluster3-controlplane1:/etc/kubernetes/manifests# watch crictl ps
```

Then we check again for the *Pod*:

```
➜ root@cluster3-controlplane1:~# kubectl get pod -l run=test
No resources found in default namespace.
```

Awesome, backup and restore worked as our pod is gone.

## 参考文档

- <https://www.cnblogs.com/informatics/p/17449393.html>
