## Jira 简介

Jira 是 Atlassian 公司出品的项目与事务跟踪工具，被广泛应用于缺陷跟踪（bug 管理）、客户服务、需求收集、流程审批、任务跟踪、项目跟踪和敏捷管理等工作领域

## Jira 总览

每个事务的相关信息均保留在与该事务关联的字段中。您可以根据贵组织的需求调整这些字段。以下图表描述了这些字段是如何通过界面和方案与事务关联的。界面是用户的事务视图，并通过界面方案映射到特定事务操作（如创建事务或编辑事务）。然后，界面方案通过事务类型界面方案映射到某个事务类型。这一配置与项目关联，因此适用于项目内的所有事务

名词：

- 问题类型方案：关联项目和问题类型
- 问题类型

- Workflow Schema（工作流方案）：关联问题类型和工作流方案
- Workflow（工作流）
- Issue Type Screen Schema（问题类型界面方案）：关联界面方案和问题类型
- Screen Schema（界面方案）：关联问题操作和界面
- Screen（界面）：关联字段到页面显示
- Field Configuration Schema（字段配置方案）：绑定字段配置和问题类型
- Filed Schema（字段配置）
- Field（自定义字段、系统字段）

一个问题包含：

- 工作流
- 界面（提交的部分）
- 字段（记录问题信息）

![image-20240408112825678](./.assets/Jira简介/image-20240408112825678.png)

![img](./.assets/Jira简介/fields_diagram.png)

通过自定义字段、界面和方案，可以充分利用 JIRA 系统的全部功能，并确保 Jira 的用户高效地工作

还可以设置通知方案，用于在用户事务更新时通知用户

## 参考文档

- <https://www.atlassian.com/zh/software/jira/templates/software-development>

- <https://doc.devpod.cn/jsm/jira-service-management-17105048.html>

- Jira 使用：<https://www.yiibai.com/jira/jira-introduction.html>

- <https://doc.devpod.cn/jira/jira-15237264.html>

- <https://blog.csdn.net/Nicolege678/article/details/124605511>

- <https://blog.csdn.net/qq_41386332/article/details/108658431>