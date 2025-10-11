安装

```bash
dnf install -y drbd drbd-utils
```

编译内核模块

```bash
ls -alh /lib/modules/$(uname -r)/build/drivers/md/bcache
make -C /lib/modules/$(uname -r)/build M=$(pwd)
```



也可以从 elrepo 安装

````bash
rpm --import https://www.elrepo.org/RPM-GPG-KEY-elrepo.org
rpm --import https://www.elrepo.org/RPM-GPG-KEY-v2-elrepo.org
# dnf install https://www.elrepo.org/elrepo-release-10.el10.elrepo.noarch.rpm -y
dnf install https://www.elrepo.org/elrepo-release-9.el9.elrepo.noarch.rpm -y
# dnf install https://www.elrepo.org/elrepo-release-8.el8.elrepo.noarch.rpm -y
dnf install kmod-drbd90 drbd90-utils -y
````

## 参考资料

- <https://axzys.cn/index.php/archives/15/>

- <https://axzys.cn/index.php/archives/19/>
- <https://blog.csdn.net/qq_34303423/article/details/106455785>

- <https://hcldirgit.github.io/2017/10/13/HA%E9%9B%86%E7%BE%A4/4.%20DRBD%E5%AE%89%E8%A3%85%E9%85%8D%E7%BD%AE%E3%80%81%E5%B7%A5%E4%BD%9C%E5%8E%9F%E7%90%86%E5%8F%8A%E6%95%85%E9%9A%9C%E6%81%A2%E5%A4%8D/>