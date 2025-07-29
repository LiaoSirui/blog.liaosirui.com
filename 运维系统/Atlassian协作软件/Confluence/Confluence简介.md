## Confluence 简介

Confluence 是由 Atlassian 开发的一个团队协作软件，它是一款专业的企业级的知识管理与协作工具

Confluence 的主要功能是帮助团队创建，组织和讨论工作。它为团队提供一个平台，在这个平台上，团队成员可以共享信息，记录决策过程，以及管理项目

Confluence 可以解决的问题：

- 知识管理：Confluence 提供了一个中心化的位置，可以创建，分享和查找信息。这包括项目计划，产品需求，研究报告，政策等
- 团队协作：Confluence 使团队可以在同一文档上协作。可以提出问题，讨论解决方案，提供反馈，或记录决策过程
- 项目管理：结合 Jira, 可以创建页面来跟踪项目的状态，记录决策，并追踪关键的项目里程碑
- 文档存档：Confluence 可以存储所有的文档，包括会议纪要，研究报告，计划等。并且可以很容易地搜索和找到这些文档

Confluence 是专门针对技术团队的文档系统，所以有各种丰富的模板，能提升工作效率

![image-20240909101359174](./.assets/Confluence简介/image-20240909101359174.png)

Confluence 集成国外几乎所有主流的工具

## 部署

镜像：<https://hub.docker.com/r/atlassian/confluence>

8091 是多人协同编辑用的 TCP 端口

## 插件

| 插件名                                  | 插件用途                                                     | 插件下载地址                                                 |
| --------------------------------------- | ------------------------------------------------------------ | ------------------------------------------------------------ |
| `Chinese Language Patch for Confluence` | 中文额外补充                                                 | <https://marketplace.atlassian.com/apps/1219843/chinese-language-patch-for-confluence> |
| `Draw.io Confluence Plugin`             | Draw.io 支持                                                 | <https://marketplace.atlassian.com/apps/1210933/draw-io-diagrams-uml-bpmn-aws-erd-flowcharts> |
| `LaTeX Math`                            | Latex 公式编辑                                               | <https://marketplace.atlassian.com/apps/1210882/latex-math>  |
| `Easy Heading Macro`                    | 插件目录可以使用 wiki 全局配置、按照空间配置、按照页面配置自由选择，并且支持内容按照标题展开、收起 | <https://marketplace.atlassian.com/apps/1221271/easy-heading-macro-floating-table-of-contents> |
| `Excalidraw for Confluence`             | 绘制手绘风格的图形，其中包含多种内置的图形库                 | <https://marketplace.atlassian.com/apps/1231435/excalidraw-for-confluence> |

备份：

| 插件名                         | 插件用途                                                     | 插件下载地址                                                 |
| ------------------------------ | ------------------------------------------------------------ | ------------------------------------------------------------ |
| Markdown for Confluence        | Markdown 支持                                                | <https://marketplace.atlassian.com/apps/1211445/markdown-for-confluence> |
| Mermaid Diagrams               | Mermaid 渲染插件                                             |                                                              |
| EasyMind for Confluence        | 绘制脑图的工具                                               |                                                              |
| Slide Presenter for Confluence | 快速制作幻灯片                                               |                                                              |
| MultiExcerpt                   | 该插件允许用户在Confluence页面上创建可重用的内容块（称为摘录）。这些摘录可以被插入到同一Confluence实例的其他页面上，并且当原始摘录更新时，所有插入的摘录也会自动更新 |                                                              |
| Advanced Roadmaps for Jira     | ，允许用户在Confluence中嵌入和展示复杂的项目路线图。这对于项目规划和追踪进度非常有帮助 |                                                              |
| Table Filter and Charts        | 筛选复杂的 Confluence 表格，在数据透视表中汇总数据，并将表格转换为创新的 Confluence 图表，以使信息易于检查 | <https://marketplace.atlassian.com/apps/27447/table-filter-and-charts-for-confluence> |
| Custom Charts                  | 利用自定义条形图、漏斗图和饼图显示支持数据或制作业务案例     | <https://marketplace.atlassian.com/apps/1220493/custom-jira-charts-confluence-reports> |
| Comala Document Control        | 为文档指派审查者或审批者，创建自定义工作流，并通过电子签名审批来确保合规 | <https://marketplace.atlassian.com/apps/1215729/comala-document-control> |
| Comala Document Management     | 文档管理                                                     | <https://marketplace.atlassian.com/apps/142/comala-document-management> |
| Command Line Interface         | 通过简单的命令自动执行任务，从而节省时间，创建可扩展的流程，并在 Confluence 和其他工具之间执行操作 | <https://marketplace.atlassian.com/apps/284/confluence-command-line-interface-cli> |
| Optics                         | 从选项卡到图像滑块再到按钮，获得您渴望的所有视觉呈现能力，以便让页面脱颖而出并清晰表达观点 | <https://marketplace.atlassian.com/apps/1222649/macrosuite-easy-html-button-hide-content-divider-tabs> |
| Render Markdown                | 以在 Confluence 页面中使用 Markdown，并显示代码块的语法重点  | <https://marketplace.atlassian.com/apps/1212654/render-markdown> |
| Content Formatting Macros      | 添加选项卡和工具提示，在表格内嵌套元素，以及添加其他格式设置元素来组织和显示内容，以提高可用性 | <https://marketplace.atlassian.com/apps/247/content-formatting-macros-for-confluence> |
| Pulse                          | 添加博文、组织结构图、新闻站点或店面等用于组织页面的元素，甚至可以添加自定义的导航菜单 | <https://marketplace.atlassian.com/apps/1224103/cards-panels> |
| Aura                           | 向页面添加按钮、轮播、倒计时等元素，使注意力集中在正确的位置 | <https://marketplace.atlassian.com/apps/1221974/aura-beautiful-formatting-macros-button-panel-tabs-cards> |
| Composition Tabs               | 利用选项卡、重点、即时焦点、菜单和可扩展区域，组织和构建极其复杂的页面 | <https://marketplace.atlassian.com/apps/245/composition-tabs-for-confluence> |
| SubSpace Navigation            | 快速将 Confluence 内容整理为单一的集中式导航菜单，并根据用户属性交付内容 | <https://marketplace.atlassian.com/apps/194/subspace-navigation-for-confluence> |
| Refined Toolkit                | 创建能反映贵公司独特观感的知识库、Wiki 或内联网              | <https://marketplace.atlassian.com/apps/1216056/refined-toolkit-for-confluence-cloud> |
| Balsamiq Wireframes            | 借助快速的线框绘制和原型设计功能，利益相关者能轻松领会您的计划并提供反馈 | <https://marketplace.atlassian.com/apps/1213404/balsamiq-wireframes-for-confluence-cloud> |
| ConfiForms                     | 在 Confluence 中，使用 30 多种自定义字段类型和丰富的设计选项快速创建表单，以征求反馈、参与调查、收集选票等 | <https://marketplace.atlassian.com/apps/1211860/confiforms-data-forms-workflows> |
| Handy Macros                   | 向页面添加号召性用语、页面投票、自定义状态元素和其他有用的协作小工具 | <https://marketplace.atlassian.com/apps/1214971/handy-macros-for-confluence-formatting-and-interactive-ui> |
| Polls                          | 无论您要计划团队活动，还是收集客户反馈，此应用都能帮助您在 Confluence 中轻松创建投票 | <https://marketplace.atlassian.com/apps/1211126/polls-for-confluence> |

插件参考：<https://doc.devpod.cn/conf/confluence-17104954.html>

- <https://marketplace.atlassian.com/apps/1222194/advanced-tabs-tabbed-page-navigation-for-confluence?hosting=datacenter&tab=overview>

- 备份数据：<https://www.baimeidashu.com/13115.html>

- <https://confluence.atlassian.com/conf89/production-backup-strategy-1387596173.html>
