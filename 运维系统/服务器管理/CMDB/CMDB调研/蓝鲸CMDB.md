## 蓝鲸 CMDB 简介

蓝鲸配置平台 (蓝鲸 CMDB) 是一个基于运维场景设计的企业配置管理服务。主要功能: 

1. 拓扑化的主机管理：主机基础属性、主机快照数据、主机归属关系管理

2. 组织架构管理：可扩展的基于业务的组织架构管理

3. 模型管理：既能管理业务、集群、主机等内置模型，也能自定义模型

4. 进程管理：基于模块的主机进程管理

5. 事件注册与推送：提供基于回调方式的事件注册与推送

6. 通用权限管理：灵活的基于用户组的权限管理

7. 操作审计：用户操作行为的审计与回溯

官网地址：<http://bk.tencent.com/>

源码地址：<https://github.com/tencent/bk-cmdb>

## 二次开发

蓝鲸的配置平台（CMDB）底层使用的是 Mongodb 作为数据存储

CMDB 是所有运维发布系统的基石，而基于蓝鲸开源 CMDB 打造企业个性化的 CMDB

仅编译后端服务

```
make server
```

仅编译前端 UI

```
make ui
```

## 参考资料

- 推送到 JMS：<https://juejin.cn/post/6985327574066921502>
- <https://cloud.tencent.com/edu/learning/course-1363-5148>
- <https://juejin.cn/post/6985135162170277896>
- <https://cloud.tencent.com/edu/learning/course-1363-5151>
- <https://www.cnblogs.com/hhxylm/p/11579123.html>