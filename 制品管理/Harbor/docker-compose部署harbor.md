## 下载离线包

官网给出了两种安装模式，在线安装包或离线安装包。其区别是离线安装包里面含有镜像，在线版本在安装时则去 Docker Hub 拉取镜像

这里使用离线安装包

最新版本可以从 github 获取：<https://github.com/goharbor/harbor/releases>

```bash
export HARBOR_VERSION=v2.5.5

cd $(mktemp -d)
wget https://github.com/goharbor/harbor/releases/download/${HARBOR_VERSION}/harbor-offline-installer-${HARBOR_VERSION}.tgz \
  -O harbor-offline-installer-${HARBOR_VERSION}.tgz

tar zxvf harbor-offline-installer-${HARBOR_VERSION}.tgz -C /data

cd /data/harbor
```

准备证书目录和证书

```bash
mkdir -p /data/harbor/https-cert

> ls -l /data/harbor/https-cert
total 16
-rw-r--r-- 1 root root 4146 Jan 24 21:53 9185667_harbor.local.liaosirui.com_nginx.zip
-rw-r--r-- 1 root root 3834 Jan 24 21:53 tls.crt
-rw-r--r-- 1 root root 1675 Jan 24 21:53 tls.key

```

## 初始化配置

在 harbor 文件夹里可以看到有一份文件 harbor.yml.tmpl，这是 Harbor 的配置信息，我们复制一份并进行修改

```bash
cp harbor.yml.tmpl harbor.yml
```

以下仅显示修改部分：

```bash
# 访问域名
yq -i '.hostname = "harbor.local.liaosirui.com"' harbor.yml
yq -i '.external_url = "https://harbor.local.liaosirui.com:5000"' harbor.yml

# 端口
yq -i '.http.port = 5001' harbor.yml
yq -i '.https.port = 5000' harbor.yml

# https 证书
yq -i '.https.certificate = "/data/harbor/https-cert/tls.crt"' harbor.yml
yq -i '.https.private_key = "/data/harbor/https-cert/tls.key"' harbor.yml

# 初始密码
yq -i '.harbor_admin_password = "LSR1142.harbor"' harbor.yml
yq -i '.database.password = "LSR1142mysql"' harbor.yml

# 数据目录
yq -i '.data_volume = "/data/harbor-data"' harbor.yml
```

## 运行 harbor

修改完毕后，直接运行

```bash
bash ./install.sh --with-trivy --with-chartmuseum
```

并等待 Docker Compose 执行完毕

部署完毕后，就可以使用这台机器的 5000 端口看到 Harbor 界面了

