对镜像的定制

```bash
# root 密码
#virt-customize -a CentOS_Linux_release_7.8.2003.qcow2 --root-password password:chenshake 

# 设置时区

virt-customize -a CentOS_Linux_release_7.8.2003.qcow2 --timezone "Asia/Shanghai" 

#安装工具

virt-customize -a CentOS_Linux_release_7.8.2003.qcow2 --install [net-tools,wget,vim,unzip,qemu-guest-agent] 

#启动服务
virt-customize -a CentOS_Linux_release_7.8.2003.qcow2 --run-command 'systemctl enable qemu-guest-agent' 


# SSH 服务
virt-sysprep -a CentOS_Linux_release_7.8.2003.qcow2 --edit '/etc/ssh/sshd_config:s/GSS/#GSS/'
virt-sysprep -a CentOS_Linux_release_7.8.2003.qcow2 --edit '/etc/ssh/sshd_config:s/#UseDNS yes/UseDNS no/'


#查看修改
virt-cat -a CentOS_Linux_release_7.8.2003.qcow2 /etc/ssh/sshd_config 


#上传优化脚本和运行
virt-customize -a CentOS_Linux_release_7.8.2003.qcow2 --upload /root/centos.sh:/root/centos.sh 
virt-customize -a CentOS_Linux_release_7.8.2003.qcow2 -chmod 755:/root/centos.sh 
virt-customize -a CentOS_Linux_release_7.8.2003.qcow2 --run '/root/centos.sh'

```

