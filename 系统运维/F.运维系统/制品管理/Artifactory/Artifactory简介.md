## Artifactory 简介

Artifactory 是一个成熟的商业版产品，支持HA，分布式部署，并且商业版本对于高并发的处理上会更有效率。Artifactory 在权限管理上做的颗粒度很细，可以满足对信息安全有严格要求的企业。在稳定性方面，经过了多家大公司的验证，以及 JFrog 在行业内的多年技术沉淀，是一款合格的商业级产品。

JFrog 发布了社区版本的 JCR (JFrog Container Registry)，作为一款功能强大且丰富的 Docker 镜像中心，JCR 已经能够在 <https://jfrog.com/container-registry/> 进行免费下载和使用。

官方简介页面：<https://www.jfrog.com/confluence/display/JFROG/JFrog+Container+Registry>

## 开源产品



## 制品仓库类型

在 jfrog 中，制品仓库又可分为四种类型：

- Local：本地仓库，一般作为内部使用
- Remote：远程仓库，一般作为代理并缓存远端仓库
- Virtual：虚拟仓库，用于组织本地仓库和管理远程仓库
- Distribution：发布仓库

### 远程仓库

定义一个代理远程npm仓库的仓库，遵循下面的步骤：

1. 在Admin模块，在 Repositories|Remote，点击 "New"
1. 在新的仓库对话，设置包的类型是 npm，设置仓库 Key 值，如下所示，指定 URL 到特定的远程仓库
1. 点击 "Save & FInish"

### 本地仓库

### 虚拟仓库

一个定义在 Artifactory 中的虚拟仓库结合了来自本地和远程的仓库。

这允许你通过一个单一的为虚拟仓库定义的URL，访问本地的 npm 包和远程的代理。

为了定义一个虚拟的 npm 仓库，创建一个 虚拟的仓库，设置包的类型是 npm,然后选择下面的需要包含在基本设置页面的本地和远程的 npm 仓库

## 多类型支持

选择一种类型后，就可以在此类型的仓库下创建不同类型的制品仓库

![img](.assets/image-20221217144414088.png)
