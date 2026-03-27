官方文档：<https://docs.vmware.com/cn/VMware-vSphere/6.5/com.vmware.vsphere.install.doc/GUID-8C9D5260-291C-44EB-A79C-BFFF506F2216.html>

在 Web 浏览器中，转至 vCenter Server Appliance 管理界面，<https://appliance-IP-address-or-FQDN:5480>

在 vCenter Server Appliance 管理界面中，单击摘要。单击备份将打开备份设备向导

输入备份协议和位置详细信息

| 选项     | 描述                                                         |
| :------- | :----------------------------------------------------------- |
| 备份协议 | 选择要用于连接备份服务器的协议。对于 FTP、FTPS、HTTP 或 HTTPS，路径对于为服务配置的主目录而言是相对的。对于 SCP，路径对于远程系统 root 目录而言是绝对的 |
| 备份位置 | 输入存储备份文件的服务器地址和备份文件夹                     |
| 端口     | 输入备份服务器的默认或自定义端口                             |
| 用户名   | 输入对备份服务器具有**写入**特权的用户的用户名               |
| 密码     | 输入对备份服务器具有**写入**特权的用户的密码                 |

支持的备份协议：

- FTP
- FTPS
- HTTP
- HTTPS
- SCP

- NFS
- SMB