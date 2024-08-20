## 什么是 Vault

Vault 是 hashicorp 推出的 secrets 管理、加密即服务与权限管理工具

Vault 是一个基于身份的秘密和加密管理系统。秘密是您想要严格控制访问的任何内容，例如 API 加密密钥、密码和证书。 Vault 提供由身份验证和授权方法控制的加密服务。使用 Vault 的 UI、CLI 或 HTTP API，可以安全地存储和管理、严格控制（限制）和审核对机密和其他敏感数据的访问

## 为什么需要 Vault

- 执行密码轮换策略很痛苦
- 掌握机密的员工离职后可能泄密或是恶意报复
- 开发者不小心把机密信息随着代码上传到公网的源码仓库造成泄密
- 管理多个系统的机密非常麻烦
- 需要将机密信息安全地加密后存储，但又不想将密钥暴露给应用程序，以防止应用程序被入侵后连带密钥一起泄漏

## Vault 架构图

Vault 只暴漏了存储后端(Storage Backend) 和 API，其他部分都被保护起来了。Vault 并不信任后端存储，存放的都是密文

![img](./.assets/Vault简介/1.png)

## 加密

![img](./.assets/Vault简介/2-20240820153737525.png)

- Vault 保存在 Backend 中的数据都是加密的
- Vault 密钥称为 Master Key 主密钥，Vault 默认使用 Shamir 算法，把主密钥切分成 M 份，管理员必须至少提供其中的 N 份才能还原出主密钥（这里的 M 和 N 都是可配置的，M>=N）理想状态下，我们必须把这 M 份密钥分配给公司内 M 个不同的人，只有在获取其中 N 个人的授权后，Vault 才可以成功解密主密钥。



## 参考文档

- <https://shuhari.dev/blog/2018/02/vault-secret-engine>

- <https://infinilabs.cn/blog/2023/vault-quickstart/>

- <https://blog.csdn.net/zhengzaifeidelushang/article/details/131291390>

- <https://just4coding.com/2020/03/13/vault-introduction/>
- <https://lonegunmanb.github.io/essential-vault/9.%E5%AE%9E%E9%99%85%E6%A1%88%E4%BE%8B/4.ssh_otp.html>