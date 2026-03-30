## 制作过程

<https://github.com/soulteary/easy-ESXi-builder>

利用 VMware-PowerCLI 软件

```dockerfile
FROM python:3.7

RUN pip config set global.index-url https://pypi.tuna.tsinghua.edu.cn/simple && pip install six psutil lxml pyopenssl --no-cache-dir

RUN wget "https://packages.microsoft.com/config/debian/11/packages-microsoft-prod.deb" -O packages-microsoft-prod.deb && dpkg -i packages-microsoft-prod.deb && rm packages-microsoft-prod.deb

RUN sed -i -e "s/deb.debian.org/mirrors.tuna.tsinghua.edu.cn/" /etc/apt/sources.list && apt-get update && apt-get install -y powershell

RUN curl -L 'https://developer.vmware.com/docs/17484/' \
  -H 'authority: developer.vmware.com' \
  -H 'accept: text/html' \
  -H 'referer: https://developer.vmware.com/powercli/installation-guide' \
  -H 'user-agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/109.0.0.0 Safari/537.36' \
  --compressed \
  -o VMware-PowerCLI-13.0.0-20829139.zip

SHELL ["/usr/bin/pwsh", "-c"]

RUN cd $($env:PSModulePath | awk -F ':' '{print $1}') && \
    mv /VMware-PowerCLI-13.0.0-20829139.zip . && \
    Expand-Archive ./VMware-PowerCLI-13.0.0-20829139.zip ./ && \
    rm -rf ./VMware-PowerCLI-13.0.0-20829139.zip

ENTRYPOINT pwsh
```

- ESXi 的离线安装包，比如：`VMware-ESXi-8.0-20513097-depot.zip`
- ESXi 相关社区驱动，搭配自己的硬件使用，比如：
  - ESXi 的 PCIe 社区网络驱动程序：[community-networking-driver-for-esxi](https://flings.vmware.com/community-networking-driver-for-esxi)
  - ESXi 的 USB 社区网络驱动程序：[usb-network-native-driver-for-esxi](https://flings.vmware.com/usb-network-native-driver-for-esxi)
  - ESXi 的 NVMe 社区驱动程序：[community-nvme-driver-for-esxi](https://flings.vmware.com/community-nvme-driver-for-esxi)

```
docker run --rm -it -v `pwd`:/data soulteary/easy-esxi-builder:2023.01.29
```

使用下面的命令，来添加基础镜像，和要附加到 ESXi 镜像中的驱动

```
# 加载基础镜像
Add-EsxSoftwareDepot /data/VMware-ESXi-8.0-20513097-depot.zip

# 加载社区 NVMe 驱动
Add-EsxSoftwareDepot /data/nvme-community-driver_1.0.1.0-3vmw.700.1.0.15843807-component-18902434.zip

# 加载社区 PCIe 驱动
Add-EsxSoftwareDepot /data/Net-Community-Driver_1.2.7.0-1vmw.700.1.0.15843807_19480755.zip

# 加载社区 USB 驱动
Add-EsxSoftwareDepot /data/ESXi800-VMKUSB-NIC-FLING-61054763-component-20826251.zip

# 如果你还需要更多驱动，参考上面的命令，继续操作即可
```

## 参考文档

- <https://soulteary.com/2023/01/29/how-to-easily-create-and-install-a-custom-esxi-image.html>