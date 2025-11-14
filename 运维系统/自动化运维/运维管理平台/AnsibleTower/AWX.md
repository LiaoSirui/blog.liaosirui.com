## AWX 简介

Ansible Tower 是企业级的 Ansible web 管理平台，提供了较为完善的观察 Ansible 任务运行的 Dashboard。Tower 允许控制访问帐号，以及分发 SSH 证书。可以通过图形界面管理清单文件或者从云进行同步。Tower 提供了任务的日志，集成 LDAP 以及 REST API。提供了方便和 Jenkins 集成的命令工具，和支持自动扩展拓扑的回调

AWX 是 Ansible Tower 的开源版，Ansible Tower 是一个可视化界面的服务器自动部署和运维管理平台。AWX 提供基于 Web 的用户界面，REST API 和构建在 Ansible 之上的任务引擎

官方：

- GitHub：<https://github.com/ansible/awx>
- 文档：<https://docs.ansible.com/ansible-tower/index.html>

## AWX 使用入门

基础概念：

- 清单（Inventories）：对应 Ansible 的 Inventory，即主机组和主机IP清单列表。
- 凭证（Credentials）：受控主机的用户名、密码（秘钥）以及提权控制
- 项目（Projects）：一个完整可运行的 Ansible 项目
- 模板（Templates）：将清单、项目和凭证关联起来的任务模板，一次创建，多次使用，可修改
- 作业（Jobs）：模板每一次运行视为一次作业

## AWX Operator 常用配置

- 使用私仓镜像：<https://docs.ansible.com/projects/awx-operator/en/latest/user-guide/advanced-configuration/deploying-a-specific-version-of-awx.html>
- 设置超管密码：<https://docs.ansible.com/projects/awx-operator/en/latest/user-guide/admin-user-account-configuration.html>

- LDAP 登录：<https://docs.ansible.com/projects/awx-operator/en/latest/user-guide/advanced-configuration/enabling-ldap-integration-at-awx-bootstrap.html>

- Operator 自动更新 Deployment：<https://docs.ansible.com/projects/awx-operator/en/latest/user-guide/advanced-configuration/auto-upgrade.html>

- 关闭 IPv6：<https://docs.ansible.com/projects/awx-operator/en/latest/user-guide/advanced-configuration/disable-ipv6.html>

- 添加额外 ENV（主要是要注入时区）：<https://docs.ansible.com/projects/awx-operator/en/latest/user-guide/advanced-configuration/exporting-environment-variables-to-containers.html>

- 自定义容器运行资源：<https://readthedocs.ansible.org.cn/projects/awx-operator/en/latest/user-guide/advanced-configuration/containers-resource-requirements.html>

- 持久化项目：<https://readthedocs.ansible.org.cn/projects/awx-operator/en/latest/user-guide/advanced-configuration/persisting-projects-directory.html>

## 参考资料

- <https://readthedocs.ansible.org.cn/projects/awx/en/latest/userguide/projects.html#scm-types-git-and-subversion>
- <https://blog.csdn.net/2301_76699451/article/details/139870013>
- <https://blog.csdn.net/weixin_43902588/article/details/116753281>
