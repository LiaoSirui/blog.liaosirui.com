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

