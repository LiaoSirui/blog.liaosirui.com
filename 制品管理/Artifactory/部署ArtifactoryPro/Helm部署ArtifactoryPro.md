官方文档：

- Installing the JFrog Platform Using Helm Chart: <https://www.jfrog.com/confluence/display/JFROG/Installing+the+JFrog+Platform+Using+Helm+Chart>
- Package Management: <https://www.jfrog.com/confluence/display/JFROG/Package+Management>

## 初始化

添加 Helm 仓库

```bash
helm repo add jfrog https://charts.jfrog.io
```

查看可用的版本

```bash
> helm search repo jfrog/artifactory

NAME                            CHART VERSION   APP VERSION     DESCRIPTION                                       
jfrog/artifactory               107.55.6        7.55.6          Universal Repository Manager supporting all maj...
jfrog/artifactory-cpp-ce        107.55.6        7.55.6          JFrog Artifactory CE for C++                      
jfrog/artifactory-ha            107.55.6        7.55.6          Universal Repository Manager supporting all maj...
jfrog/artifactory-jcr           107.55.6        7.55.6          JFrog Container Registry                          
jfrog/artifactory-oss           107.55.6        7.55.6          JFrog Artifactory OSS   
```

拉取 chart

```bash
helm pull jfrog/artifactory --version 11.4.5

# 拉取并解压
helm pull jfrog/artifactory --version 11.4.5 --untar
```

创建命名空间

```bash
kubectl create ns artifactory
```

生成 master key 和 join key，在正式生产环境部署需要固定这两个 key，方便后期维护集群

创建  Master Key

```bash
# Create a key
export MASTER_KEY=$(openssl rand -hex 32)
echo ${MASTER_KEY}
# 68884a25b2d196815f78583c85434f800d1c497d4ab95284af9d08bdf8c95b0d
 
# Create a secret containing the key. The key in the secret must be named master-key
# kubectl create secret generic my-masterkey-secret -n artifactory --from-literal=master-key=${MASTER_KEY}
```

创建 Join Key

```bash
# Create a key
export JOIN_KEY=$(openssl rand -hex 32)
echo ${JOIN_KEY}
# 2e367b1ef373d43f018ef965fbffe03f1bbe399f0e3d69a8ea28643153e86f78

# Create a secret containing the key. The key in the secret must be named join-key
# kubectl create secret generic my-joinkey-secret -n artifactory --from-literal=join-key=${JOIN_KEY}
```

## 准备 pv

准备目录，记得授权 777 否则 启动可能失败（具体的权限码没有去研究，好像是 1030 用户和组）

```bash
mkdir -p /data/sdb/artifactory/{pg_data,app_data}
chmod 777 /data/sdb/artifactory/{pg_data,app_data}
```

创建 pg data 的 pv

```yaml
kind: PersistentVolumeClaim
apiVersion: v1
metadata:
  name: data-artifactory-postgresql-0
  namespace: artifactory
  labels:
    app.kubernetes.io/instance: artifactory
    app.kubernetes.io/name: postgresql
    role: master
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 50Gi
  volumeMode: Filesystem
  selector:
    matchLabels:
      app.kubernetes.io/instance: artifactory
      app.kubernetes.io/name: postgresql
      role: primary

---
kind: PersistentVolume
apiVersion: v1
metadata:
  name: data-artifactory-postgresql-pv
  labels:
    app.kubernetes.io/instance: artifactory
    app.kubernetes.io/name: postgresql
    role: primary
spec:
  capacity:
    storage: 200Gi
  hostPath:
    path: /data/sdb/artifactory/pg_data
    type: DirectoryOrCreate
  accessModes:
    - ReadWriteOnce
  volumeMode: Filesystem
  nodeAffinity:
    required:
      nodeSelectorTerms:
        - matchExpressions:
            - key: kubernetes.io/hostname
              operator: In
              values:
                - devmaster
```

创建 app data 的 pv

```yaml
kind: PersistentVolumeClaim
apiVersion: v1
metadata:
  name: artifactory-volume-artifactory-artifactory-0
  namespace: artifactory
  labels:
    app: artifactory
    release: artifactory
    role: artifactory
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 20Gi
  volumeMode: Filesystem
  selector:
    matchLabels:
      app: artifactory
      release: artifactory
      role: artifactory

---
kind: PersistentVolume
apiVersion: v1
metadata:
  name: artifactory-volume-artifactory-pv
  labels:
    app: artifactory
    release: artifactory
    role: artifactory
spec:
  capacity:
    storage: 200Gi
  hostPath:
    path: /data/sdb/artifactory/app_data
    type: DirectoryOrCreate
  accessModes:
    - ReadWriteOnce
  volumeMode: Filesystem
  nodeAffinity:
    required:
      nodeSelectorTerms:
        - matchExpressions:
            - key: kubernetes.io/hostname
              operator: In
              values:
                - devmaster
```

## 部署

使用 values.yaml 覆盖默认配置：

```yaml
rbac:
  create: true

serviceAccount:
  create: true

artifactory:
  masterKey: 68884a25b2d196815f78583c85434f800d1c497d4ab95284af9d08bdf8c95b0d
  joinKey: 2e367b1ef373d43f018ef965fbffe03f1bbe399f0e3d69a8ea28643153e86f78
  image:
    registry: releases-docker.jfrog.io
    repository: jfrog/artifactory-pro
    # tag:
    pullPolicy: IfNotPresent
  admin:
    ip: "127.0.0.1"
    username: "admin"
    password: "abc123!"
  persistence:
    enabled: true
    size: 200Gi
    type: file-system
    storageClassName: "-"
  tolerations:
    - operator: Exists

nginx:
  persistence:
    enabled: false
  tolerations:
    - operator: Exists
  nodeSelector:
    kubernetes.io/hostname: devmaster

postgresql:
  persistence:
    enabled: true
    size: 50Gi
  master:
    tolerations:
      - operator: Exists
    nodeSelector:
      kubernetes.io/hostname: devmaster

```

使用 helm 部署

```bash
helm upgrade --install \
  -f ./values.yaml \
  --namespace artifactory --create-namespace \
  --version 11.4.5 \
  artifactory jfrog/artifactory
```

## 手动建 ingress

```yaml
kind: Secret
apiVersion: v1
metadata:
  name: artifactory-https-tls
  namespace: artifactory
data:
  tls.crt: >-
    LS0tLS1CRUdJTiBDRVJUSUZJQ0FURS0tLS0tCk1JSUZWVENDQkQyZ0F3SUJBZ0lTQTlvU08yMzUxK3NGQnNmc1pkbjRrMmRiTUEwR0NTcUdTSWIzRFFFQkN3VUEKTURJeEN6QUpCZ05WQkFZVEFsVlRNUll3RkFZRFZRUUtFdzFNWlhRbmN5QkZibU55ZVhCME1Rc3dDUVlEVlFRRApFd0pTTXpBZUZ3MHlNekF5TURrd056VXdNVFZhRncweU16QTFNVEF3TnpVd01UUmFNRE14TVRBdkJnTlZCQU1UCktHdDFZbVZ5Ym1WMFpYTXRaR0Z6YUdKdllYSmtMbXh2WTJGc0xteHBZVzl6YVhKMWFTNWpiMjB3Z2dFaU1BMEcKQ1NxR1NJYjNEUUVCQVFVQUE0SUJEd0F3Z2dFS0FvSUJBUUQ2OUxhZDRZMi9EMThSWU9uc0RYdTlLZnp3bnpZeQo4cVdmNDVDaUo2Yzd1UHdJdTFlSzk3NEUzYU9rTzExQlJKN2pZNml3TldIWGE3YlZSeUJiNmJVeVRUM0Nld3QyCnNkUHZaNEFnRDdSdkgzWk1DZzFNZENKVjBsdjZtaklFcEtsNFlsUkduQTJIcDN0bUE0ekJNTEFHdm1sRXVCTTMKcHlRKzBhQmZwanhnbkZnNVo5M1lDRXlNaVNIaG5hZCtLN3JwR1ZXcXAyS2hPN3dSUFo4ZDJEaGhBRGpHNnFFdQpCK1B6YTVYZGtFL2VWQ3lDMVNnbG5DL0VxTTBIMGhqWmQrUHkwWTY3K1N0Z0h3U1pHRmFPWlpCWXJMM1UyWFJhCmpabUxBc3A0NzZ6RCtTL24xSHljUzdZbHJjbzFHRksvWGQ4RmhnNUZGZUVrS3VSSlo4UjJ0ZWZqQWdNQkFBR2oKZ2dKaU1JSUNYakFPQmdOVkhROEJBZjhFQkFNQ0JhQXdIUVlEVlIwbEJCWXdGQVlJS3dZQkJRVUhBd0VHQ0NzRwpBUVVGQndNQ01Bd0dBMVVkRXdFQi93UUNNQUF3SFFZRFZSME9CQllFRk9uelpCYkpDSnp4dzlQQ3UxS2xkNkVPCmJFTFdNQjhHQTFVZEl3UVlNQmFBRkJRdXN4ZTNXRmJMcmxBSlFPWWZyNTJMRk1MR01GVUdDQ3NHQVFVRkJ3RUIKQkVrd1J6QWhCZ2dyQmdFRkJRY3dBWVlWYUhSMGNEb3ZMM0l6TG04dWJHVnVZM0l1YjNKbk1DSUdDQ3NHQVFVRgpCekFDaGhab2RIUndPaTh2Y2pNdWFTNXNaVzVqY2k1dmNtY3ZNRE1HQTFVZEVRUXNNQ3FDS0d0MVltVnlibVYwClpYTXRaR0Z6YUdKdllYSmtMbXh2WTJGc0xteHBZVzl6YVhKMWFTNWpiMjB3VEFZRFZSMGdCRVV3UXpBSUJnWm4KZ1F3QkFnRXdOd1lMS3dZQkJBR0MzeE1CQVFFd0tEQW1CZ2dyQmdFRkJRY0NBUllhYUhSMGNEb3ZMMk53Y3k1cwpaWFJ6Wlc1amNubHdkQzV2Y21jd2dnRURCZ29yQmdFRUFkWjVBZ1FDQklIMEJJSHhBTzhBZFFDM1B2c2szNXhOCnVuWHlPY1c2V1BSc1hmeEN6M3FmTmNTZUhRbUJKZTIwbVFBQUFZWTFYa1N1QUFBRUF3QkdNRVFDSUVPaS9jL00KTll6ZzdvamtPWkJmU1hTRVRBcktZem9MVG5tb3VFb0RvYzBiQWlCKytyUUZJLy82YzhTRHNaSHBOaU5Za29mdgpkVVBDOUMxWVR4VDkzbnZQdUFCMkFLMzN2dnA4L3hESWk1MDluQjQrR0dxMFp5bGR6N0VNSk1xRmhqVHIzSUtLCkFBQUJoalZlUk5NQUFBUURBRWN3UlFJaEFKc09YQ3M5OE5XUW9XSGtrUEV5TklOdTROZnV5aHl1aVJyRGxJL1UKVEp6V0FpQmR2SEFDT0RoR1dPWFc1RFM5Z3NyZElZdjl0K2g3cE5RbFoyUlEyYzdzTkRBTkJna3Foa2lHOXcwQgpBUXNGQUFPQ0FRRUFoeFZFc3pHSnFMUVVzWWRMK0ZxUVRreVNOd0NyOWs5a0lzTVZ1c1ZZdGlkQ3VaMk1wSkVDCnFoVG00RlEvNWhDWmNLZlRucUJJK1ozczErVW5IblpjdVEzWHkyQXJFZjMrczhWSHJ5cTVsazZWdnNCSWIzalkKTWpLeExUd2VDUndxZGJIYUc0MUg1eFRaU1NUTGdBYjBlVERiU082dWllaDhtUFJnNGUxWkdQWEFXVUxKcVFqaApDNVRMZU14YVppYllzZnloWVZSd1UzQUlQUUVqd0E5Mi9ZemgvamxrTGtMaTdWOTlHVjJXMXZBNkdSdzFocis0CjlFZkdlYXUyRlpIUGJrc3Z1K2ZiUmFSVmh5eXJkNHZOOHo4SE1id3RYU2FQcUEvVGRUeTZwSXRhbnV0clNLbSsKcUc1L0Z5S3FaKzdSbnNyNVd2SVRQcjlmZG5SdXlsdkZLdz09Ci0tLS0tRU5EIENFUlRJRklDQVRFLS0tLS0KLS0tLS1CRUdJTiBDRVJUSUZJQ0FURS0tLS0tCk1JSUZGakNDQXY2Z0F3SUJBZ0lSQUpFckNFclBEQmluVS9iV0xpV25YMW93RFFZSktvWklodmNOQVFFTEJRQXcKVHpFTE1Ba0dBMVVFQmhNQ1ZWTXhLVEFuQmdOVkJBb1RJRWx1ZEdWeWJtVjBJRk5sWTNWeWFYUjVJRkpsYzJWaApjbU5vSUVkeWIzVndNUlV3RXdZRFZRUURFd3hKVTFKSElGSnZiM1FnV0RFd0hoY05NakF3T1RBME1EQXdNREF3CldoY05NalV3T1RFMU1UWXdNREF3V2pBeU1Rc3dDUVlEVlFRR0V3SlZVekVXTUJRR0ExVUVDaE1OVEdWMEozTWcKUlc1amNubHdkREVMTUFrR0ExVUVBeE1DVWpNd2dnRWlNQTBHQ1NxR1NJYjNEUUVCQVFVQUE0SUJEd0F3Z2dFSwpBb0lCQVFDN0FoVW96UGFnbE5NUEV1eU5WWkxEK0lMeG1hWjZRb2luWFNhcXRTdTV4VXl4cjQ1citYWElvOWNQClI1UVVWVFZYako2b29qa1o5WUk4UXFsT2J2VTd3eTdiamNDd1hQTlpPT2Z0ejJud1dnc2J2c0NVSkNXSCtqZHgKc3hQbkhLemhtKy9iNUR0RlVrV1dxY0ZUempUSVV1NjFydTJQM21CdzRxVlVxN1p0RHBlbFFEUnJLOU84WnV0bQpOSHo2YTR1UFZ5bVorREFYWGJweWIvdUJ4YTNTaGxnOUY4Zm5DYnZ4Sy9lRzNNSGFjVjNVUnVQTXJTWEJpTHhnClozVm1zL0VZOTZKYzVsUC9Pb2kyUjZYL0V4anFtQWwzUDUxVCtjOEI1ZldtY0JjVXIyT2svNW16azUzY1U2Y0cKL2tpRkhhRnByaVYxdXhQTVVnUDE3VkdoaTlzVkFnTUJBQUdqZ2dFSU1JSUJCREFPQmdOVkhROEJBZjhFQkFNQwpBWVl3SFFZRFZSMGxCQll3RkFZSUt3WUJCUVVIQXdJR0NDc0dBUVVGQndNQk1CSUdBMVVkRXdFQi93UUlNQVlCCkFmOENBUUF3SFFZRFZSME9CQllFRkJRdXN4ZTNXRmJMcmxBSlFPWWZyNTJMRk1MR01COEdBMVVkSXdRWU1CYUEKRkhtMFdlWjd0dVhrQVhPQUNJaklHbGoyNlp0dU1ESUdDQ3NHQVFVRkJ3RUJCQ1l3SkRBaUJnZ3JCZ0VGQlFjdwpBb1lXYUhSMGNEb3ZMM2d4TG1rdWJHVnVZM0l1YjNKbkx6QW5CZ05WSFI4RUlEQWVNQnlnR3FBWWhoWm9kSFJ3Ck9pOHZlREV1WXk1c1pXNWpjaTV2Y21jdk1DSUdBMVVkSUFRYk1Ca3dDQVlHWjRFTUFRSUJNQTBHQ3lzR0FRUUIKZ3Q4VEFRRUJNQTBHQ1NxR1NJYjNEUUVCQ3dVQUE0SUNBUUNGeWs1SFBxUDNoVVNGdk5WbmVMS1lZNjExVFI2VwpQVE5sY2xRdGdhRHF3KzM0SUw5ZnpMZHdBTGR1Ty9aZWxON2tJSittNzR1eUErZWl0Ulk4a2M2MDdUa0M1M3dsCmlrZm1aVzQvUnZUWjhNNlVLKzVVemhLOGpDZEx1TUdZTDZLdnpYR1JTZ2kzeUxnamV3UXRDUGtJVno2RDJRUXoKQ2tjaGVBbUNKOE1xeUp1NXpsenlaTWpBdm5uQVQ0NXRSQXhla3JzdTk0c1E0ZWdkUkNuYldTRHRZN2toK0JJbQpsSk5Yb0IxbEJNRUtJcTRRRFVPWG9SZ2ZmdURnaGplMVdyRzlNTCtIYmlzcS95Rk9Hd1hEOVJpWDhGNnN3Nlc0CmF2QXV2RHN6dWU1TDNzejg1SytFQzRZL3dGVkROdlpvNFRZWGFvNlowZitsUUtjMHQ4RFFZemsxT1hWdThycDIKeUpNQzZhbExiQmZPREFMWnZZSDduN2RvMUFabHM0STlkMVA0am5rRHJRb3hCM1VxUTloVmwzTEVLUTczeEYxTwp5SzVHaEREWDhvVmZHS0Y1dStkZWNJc0g0WWFUdzdtUDNHRnhKU3F2MyswbFVGSm9pNUxjNWRhMTQ5cDkwSWRzCmhDRXhyb0wxKzdtcnlJa1hQZUZNNVRnTzlyMHJ2WmFCRk92VjJ6MGdwMzVaMCtMNFdQbGJ1RWpOL2x4UEZpbisKSGxVanI4Z1JzSTNxZkpPUUZ5LzlyS0lKUjBZLzhPbXd0LzhvVFdneTFtZGVIbW1qazdqMW5Zc3ZDOUpTUTZadgpNbGRsVFRLQjN6aFRoVjErWFdZcDZyamQ1SlcxemJWV0VrTE54RTdHSlRoRVVHM3N6Z0JWR1A3cFNXVFVUc3FYCm5MUmJ3SE9vcTdoSHdnPT0KLS0tLS1FTkQgQ0VSVElGSUNBVEUtLS0tLQotLS0tLUJFR0lOIENFUlRJRklDQVRFLS0tLS0KTUlJRllEQ0NCRWlnQXdJQkFnSVFRQUYzSVRmVTZVSzQ3bmFxUEdRS3R6QU5CZ2txaGtpRzl3MEJBUXNGQURBLwpNU1F3SWdZRFZRUUtFeHRFYVdkcGRHRnNJRk5wWjI1aGRIVnlaU0JVY25WemRDQkRieTR4RnpBVkJnTlZCQU1UCkRrUlRWQ0JTYjI5MElFTkJJRmd6TUI0WERUSXhNREV5TURFNU1UUXdNMW9YRFRJME1Ea3pNREU0TVRRd00xb3cKVHpFTE1Ba0dBMVVFQmhNQ1ZWTXhLVEFuQmdOVkJBb1RJRWx1ZEdWeWJtVjBJRk5sWTNWeWFYUjVJRkpsYzJWaApjbU5vSUVkeWIzVndNUlV3RXdZRFZRUURFd3hKVTFKSElGSnZiM1FnV0RFd2dnSWlNQTBHQ1NxR1NJYjNEUUVCCkFRVUFBNElDRHdBd2dnSUtBb0lDQVFDdDZDUno5QlEzODV1ZUsxY29ISWUrM0xmZk9KQ01ianptVjZCNDkzWEMKb3Y3MWFtNzJBRThvMjk1b2hteEVrN2F4WS8wVUVtdS9IOUxxTVpzaGZ0RXpQTHBJOWQxNTM3TzQveEx4SVpwTAp3WXFHY1dsS1ptWnNqMzQ4Y0wrdEtTSUc4K1RBNW9DdTRrdVB0NWwrbEFPZjAwZVhmSmxJSTFQb09LNVBDbStECkx0RkpWNHlBZExiYUw5QTRqWHNEY0NFYmRmSXdQUHFQcnQzYVk2dnJGay9DamhGTGZzOEw2UCsxZHk3MHNudEsKNEV3U0pReHdqUU1wb09GVEpPd1QyZTRadnhDelNvdy9pYU5oVWQ2c2h3ZVU5R054N0M3aWIxdVlnZUdKWERSNQpiSGJ2TzVCaWVlYmJwSm92SnNYUUVPRU8zdGtRamhiN3QvZW85OGZsQWdlWWp6WUlsZWZpTjVZTk5uV2UrdzV5CnNSMmJ2QVA1U1FYWWdkMEZ0Q3JXUWVtc0FYYVZDZy9ZMzlXOUVoODFMeWdYYk5LWXdhZ0paSGR1UnplNnpxeFoKWG1pZGYzTFdpY1VHUVNrK1dUN2RKdlVreVJHbldxTk1RQjlHb1ptMXB6cFJib1k3bm4xeXB4SUZlRm50UGxGNApGUXNEajQzUUx3V3lQbnRLSEV0ekJSTDh4dXJnVUJOOFE1TjBzOHAwNTQ0ZkFRalFNTlJiY1RhMEI3ckJNREJjClNMZUNPNWltZldDS29xTXBnc3k2dllNRUc2S0RBMEdoMWdYeEc4SzI4S2g4aGp0R3FFZ3FpTngybW5hL0gycWwKUFJtUDZ6anpaTjdJS3cwS0tQLzMyK0lWUXRRaTBDZGQ0WG4rR09kd2lLMU81dG1MT3NiZEoxRnUvN3hrOVRORApUd0lEQVFBQm80SUJSakNDQVVJd0R3WURWUjBUQVFIL0JBVXdBd0VCL3pBT0JnTlZIUThCQWY4RUJBTUNBUVl3ClN3WUlLd1lCQlFVSEFRRUVQekE5TURzR0NDc0dBUVVGQnpBQ2hpOW9kSFJ3T2k4dllYQndjeTVwWkdWdWRISjEKYzNRdVkyOXRMM0p2YjNSekwyUnpkSEp2YjNSallYZ3pMbkEzWXpBZkJnTlZIU01FR0RBV2dCVEVwN0drZXl4eAordHZoUzVCMS84UVZZSVdKRURCVUJnTlZIU0FFVFRCTE1BZ0dCbWVCREFFQ0FUQS9CZ3NyQmdFRUFZTGZFd0VCCkFUQXdNQzRHQ0NzR0FRVUZCd0lCRmlKb2RIUndPaTh2WTNCekxuSnZiM1F0ZURFdWJHVjBjMlZ1WTNKNWNIUXUKYjNKbk1Ed0dBMVVkSHdRMU1ETXdNYUF2b0MyR0syaDBkSEE2THk5amNtd3VhV1JsYm5SeWRYTjBMbU52YlM5RQpVMVJTVDA5VVEwRllNME5TVEM1amNtd3dIUVlEVlIwT0JCWUVGSG0wV2VaN3R1WGtBWE9BQ0lqSUdsajI2WnR1Ck1BMEdDU3FHU0liM0RRRUJDd1VBQTRJQkFRQUtjd0JzbG03L0RsTFFydDJNNTFvR3JTK280NCsveVFvREZWREMKNVd4Q3UyK2I5TFJQd2tTSUNIWE02d2ViRkdKdWVON3NKN281WFBXaW9XNVdsSEFRVTdHNzVLL1Fvc01yQWRTVwo5TVVnTlRQNTJHRTI0SEdOdExpMXFvSkZsY0R5cVNNbzU5YWh5MmNJMnFCRExLb2JreC9KM3ZXcmFWMFQ5VnVHCldDTEtUVlhrY0dkdHdsZkZSamxCejRwWWcxaHRtZjVYNkRZTzhBNGpxdjJJbDlEalhBNlVTYlcxRnpYU0xyOU8KaGU4WTRJV1M2d1k3YkNrakNXRGNSUUpNRWhnNzZmc08zdHhFK0ZpWXJ1cTlSVVdoaUYxbXl2NFE2VytDeUJGQwpEZnZwN09PR0FONmRFT000K3FSOXNkam9TWUtFQnBzcjZHdFBBUXc0ZHk3NTNlYzUKLS0tLS1FTkQgQ0VSVElGSUNBVEUtLS0tLQo=
  tls.key: >-
    LS0tLS1CRUdJTiBSU0EgUFJJVkFURSBLRVktLS0tLQpNSUlFb3dJQkFBS0NBUUVBK3ZTMm5lR052dzlmRVdEcDdBMTd2U244OEo4Mk12S2xuK09Rb2llbk83ajhDTHRYCml2ZStCTjJqcER0ZFFVU2U0Mk9vc0RWaDEydTIxVWNnVyttMU1rMDl3bnNMZHJIVDcyZUFJQSswYng5MlRBb04KVEhRaVZkSmIrcG95QktTcGVHSlVScHdOaDZkN1pnT013VEN3QnI1cFJMZ1RONmNrUHRHZ1g2WThZSnhZT1dmZAoyQWhNaklraDRaMm5maXU2NlJsVnFxZGlvVHU4RVQyZkhkZzRZUUE0eHVxaExnZmo4MnVWM1pCUDNsUXNndFVvCkpad3Z4S2pOQjlJWTJYZmo4dEdPdS9rcllCOEVtUmhXam1XUVdLeTkxTmwwV28yWml3TEtlTytzdy9rdjU5UjgKbkV1MkphM0tOUmhTdjEzZkJZWU9SUlhoSkNya1NXZkVkclhuNHdJREFRQUJBb0lCQUdxTTB5cG1kVW50SzFhVQpHTTJ1RGQ4TGdFYmp1bDNZVTBUM0dGWVkwdkxUQUVOdTAyVC8rZkJUOEdKUENER3BnbktXUWkyS2hMK3pqcDJ3ClJNZHhpNHJQYTh6eWREUVJuYVBVaEh4WVhxb2RxQnJ4MjZLZDNtUWszQU9qUzJCWVQxSDdJY0FYQ3RHUlpSMnoKblNQN1dZbUxkK09DNmpualg4ckNNejdaTkdKcHQvZG4wMlo3ZTlzaDYwcmFYa3NncUVudDU3YVljMjd2NG9xMwpKWnpIZHJBNE0wSW42Q0tobkZQYUpSV2dNNXE5T1M0OTVYVDBYaGZGdmtoaU9UWnRIZy8vbFMyUTBFbC8xaTMrCjNTTm5aWXkyUjZTbnV5emN0SjA1UFhZRFFiSFJOWnRodldyTW1zSmsxZTI4VjhLek5odVlOSzBmRmJQZ2pUbjMKSGIwQU02MENnWUVBK3k4MGZIU0sxRTVwTHRMV1lyRFU0RnhXTWdxeHkyWFhVSkVycktUUHlWL3ROUmszL2srMAp3RUdwWXd4Slo1eFdLdHJTVFMxV3FnZm5pTGZla3BUZzhyS3N5WDFiakNsS1RQRXcvVUM2aFlrK0xVSjQyUkF3CitpL2xEL3NoTHluSWUyV2RkYU8zaWlZU1d3Q05pMjV0enpoNm15L09NL2FFVE9tWGtWTWdVMzhDZ1lFQS84UmoKRHIvcFp6d3IvUlF1bVhHbFg2QVJMSVJPZ0V3RXlMckJvK2RmOFFtOTdBYXdrOGpOb1pYbnZyMmh4b1JBNjVOKwpkNkw5OHZYekQvaWpBMEJOeTkxUVZoMDBqVzZTNGo2LzY1RE1DZ1hOVUhPZUlCRWJBY1ZqajVSVG9Sd2FPLzFvCkxsMnFiVFdlNGFvSkNHcVZZdW1tWENPeHZPazNwU3lsMlhINnpaMENnWUFTNFVOeXIxZllDV1RDampwckJKdWIKbVpVcEFjREhad28rRmd0UVdMcjlpZVpNZlc3R0FMdTNUN2dwcDd6RXV1MkhIeGQ3a1pMWUNPd1FUTEhBRnN5cApzV0JuYkxLNjRFZWpiT1dmdzRQQmtjVklwWnhyeEZuS0ZGdUZUZno2akl0ekt2b2c0NE5pTU9aa1RMQlc4Si8wCldXeHR5YlFZRjhsdDlvamI5WUdTaFFLQmdRRFFyWXZndWVZV1M3cmNOdjQ2UmNZVytrTm8zZDRxd1Z0WjV6NGMKbTZma3d2MEpPUUFTNDlBYW1YTkdaZlE3UXlhd3psdHVBemROWnl4VWlKbUFDcFF1MURnNnVvTnBMYUY4SkpSegovMlRxZklkaXI2S0JLVk91b3owekpXTUNYU3B1YmJmMXRJaGJxRmNrYVpZTEh1TVptK2NXNEN5aEpHczVRZTlqCk5hTGE1UUtCZ0dhRUREZEt5NkIyQWdRQjhIcEpOSTJqLzZiSGxWeEdtUUtiaUE5d05pM1hRUmRPYXhaekhqMzAKSk9PMUwzbnpFQmVKUGx4SlFHYmJ6cWE3SzRUT3k0OEtsL05PR3dyc3N4Yi9RdjNsZTFPbzhDbjZib1hqTkwzLwpYL2xWSlNzbHZvbk1yM1ppWFd0eHQ3MkVxYkhvVlp4Q2xWaUpRR3k4OWJDQllONC9KRjl4Ci0tLS0tRU5EIFJTQSBQUklWQVRFIEtFWS0tLS0tCg==
type: kubernetes.io/tls

---
kind: Ingress
apiVersion: networking.k8s.io/v1
metadata:
  annotations:
    kubernetes.io/ingress.class: nginx
    cert-manager.io/cluster-issuer: cert-http01
    nginx.ingress.kubernetes.io/force-ssl-redirect: "true"
    nginx.ingress.kubernetes.io/ssl-redirect: "true"
    nginx.ingress.kubernetes.io/proxy-body-size: "1024m"
  name: artifactory
  namespace: artifactory
  labels: {}
spec:
  tls:
    - hosts:
        - repos.local.liaosirui.com
      secretName: artifactory-https-tls
  rules:
    - host: repos.local.liaosirui.com
      http:
        paths:
          - path: /
            pathType: ImplementationSpecific
            backend:
              service:
                name: artifactory-artifactory-nginx
                port:
                  number: 80

```

## hack

运行 docker 进行 hack

```bash
docker run -it --rm --entrypoint=sh \
 --name artifactory \
 -v ${PWD}:${PWD} -w ${PWD} \
 --security-opt seccomp=unconfined \
 harbor.local.liaosirui.com:5000/3rdparty/releases-docker.jfrog.io/jfrog/artifactory-pro:7.10.6
```

执行如下步骤

```bash
# 容器内 JVM 路径：/opt/jfrog/artifactory/app/third-party/java/bin/java
# 启动 war 包所在的路径：/opt/jfrog/artifactory/app/artifactory/tomcat

> /opt/jfrog/artifactory/app/third-party/java/bin/java -jar ./artifactory-injector-1.1.jar
What do you want to do?
1 - generate License String
2 - inject artifactory
exit - exit
2
where is artifactory home? ("back" for back)
/opt/jfrog/artifactory/app/artifactory/tomcat
artifactory detected. continue? (yes/no)
yes
putting another WEB-INF/lib/artifactory-addons-manager-6.6.0.jar
META-INF/
org/
org/jfrog/
...
What do you want to do?
1 - generate License String
2 - inject artifactory
exit - exit
exit
```

默认使用如下 key

```text
eyJhcnRpZmFjdG9yeSI6eyJpZCI6IiIsIm93bmVyIjoicjRwMyIsInZhbGlkRnJvbSI6MTYzNDEzODYwNDc5MSwiZXhwaXJlcyI6NDc4OTgxMjIwNDc2NiwidHlwZSI6IkVOVEVSUFJJU0VfUExVUyIsInRyaWFsIjpmYWxzZSwicHJvcGVydGllcyI6e319fQ==
```

提交镜像

```bash
docker commit harbor.local.liaosirui.com:5000/3rdparty/docker.bintray.io/jfrog/artifactory-pro:7.10.6-hack

docker push harbor.local.liaosirui.com:5000/3rdparty/docker.bintray.io/jfrog/artifactory-pro:7.10.6-hack
```
