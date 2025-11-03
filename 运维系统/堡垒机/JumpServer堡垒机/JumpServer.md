## JumpServer 简介

JumpServer 是一款全球首创的完全开源堡垒机，采用 GNU GPL v2.0 开源协议。它是一个专业的运维审计系统，符合 4A（认证 Authentication、账号 Account、授权 Authorization、审计 Audit）标准

JumpServer 是基于 Python/Django 开发的，符合 Web 2.0 规范，具备业界领先的 Web Terminal 解决方案，提供美观的交互界面和出色的用户体验。系统采用分布式架构，支持多机房跨区域部署。中心节点提供 API，而各机房部署登录节点，可以轻松横向扩展，没有并发访问限制

JumpServer 采纳分布式架构，支持多机房跨区域部署，支持横向扩展，无资产数量及并发限制；这使得 Jumpserver 成为一个高度灵活和可扩展的堡垒机解决方案

![img](.assets/JumpServer/js-enterprise-20240118053609156.png)

组件架构如下：

![architecture_01](./.assets/JumpServer/architecture_01.png)

- Core 组件是 JumpServer 的核心组件，其他组件依赖此组件启动
- Koko 是服务于类 Unix 资产平台的组件，通过 SSH、Telnet 协议提供字符型连接
- Lion 是服务于 Windows 资产平台的组件，用于 Web 端访问 Windows 资产
- XRDP 是服务于 RDP 协议组件，该组件主要功能是通过 JumpServer Client 方式访问 windows 2000、XP 等系统的资产
- Razor 是服务于 RDP 协议组件，JumpServer Client 默认使用 Razor 组件访问 Windows 资产
- Magnus 是服务于数据库的组件，用于通过客户端代理访问数据库资产
- Kael 是服务于 GPT 资产平台的组件，用于纳管 ChatGPT 资产
- Chen 是服务于数据库的组件，用于通过 Web GUI 方式访问数据库资产
- Celery 是处理异步任务的组件，用于执行 JumpServer 相关的自动化任务
- Video 是专门处理 Razor 组件和 Lion 组件产生录像的格式转换工作，将产生的会话录像转化为 MP4 格式
- Panda 是基于国产操作系统的应用发布机，用于调度 Virtualapp 应用

官方：

- <https://github.com/jumpserver>
- <https://github.com/jumpserver/helm-charts>
- <https://docs.jumpserver.org/zh/v4/>

## JumpServer 安装

### helm 安装



```bash
helm repo add jumpserver https://jumpserver.github.io/helm-charts
```

### compose 安装

初始用户名/密码：admin/admin，第一次登录，会强制要求修改密码

参考：<https://github.com/jumpserver/Dockerfile/blob/master/docker-compose.yml>

## JumpServer 配置

### OIDC 登录

官方文件：<https://docs.jumpserver.org/zh/master/admin-guide/authentication/openid/>

### MFA

清理所有 MFA

```python
from users.models import User
receivers = User.objects.values_list("username", flat=True)
all_users = []
for r in receivers:
    all_users.append(r)

for u_name in all_users:
    u = User.objects.get(username=u_name)
    u.mfa_level='0'
    u.otp_secret_key=''
    u.save()

```

## 参考资料

- Jumpserver安全一窥：Sep系列漏洞深度解析 <https://www.leavesongs.com/PENETRATION/jumpserver-sep-2023-multiple-vulnerabilities-go-through.html>
