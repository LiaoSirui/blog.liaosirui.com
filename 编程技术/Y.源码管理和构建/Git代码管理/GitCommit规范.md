
## 受欢迎的规范

- 目前最受开发人员肯定的规范是前端框架 Angular 提出的 Angular 提交信息规范：<https://github.com/angular/angular/blob/main/CONTRIBUTING.md#commit>
- <https://github.com/conventional-commits/conventionalcommits.org>

## 规范

提交格式如下：

```text
<type>[,<type2>...](<scope>)<!>: <subject> # <jira issue id>,[<jira issue id2> ...]
<BLANK LINE>
<body>
<BLANK LINE>
<footer>
```

每次提交可以包含页眉 (header)、正文(body) 和页脚 (footer)，每次提交必须包含页眉内容

每次提交的信息原则上不超过 100 个字符

### （1）页眉部分-Header

页眉的格式指定为提交类型（type）、作用域（scope）和主题（subject）、Jira issue id

- 提交类型

提交类型指定为下面其中一个或者多个：

| 类型        | 提示符 用于生成工具的交互界面 | 含义                                                    |
| :---------- | :---------------------------- | :------------------------------------------------------ |
| chore       | 🗯  chore                      | 杂务 不属于以上类型 例如 run build、引入或更新软件包等  |
| ci          | 🔧  ci                         | 修改 ci 相关配置、脚本等                                |
| config      | 📝  config                     | 修改或添加配置文件                                      |
| deploy      | ⏺ deploy                      | 修改部署或配置相关的文件、脚本等                        |
| docs        | 📚  docs                       | 变更文档                                                |
| feat        | ✨  feat                       | 一个新特性                                              |
| fix         | 🐛  fix                        | 修复 Bug                                                |
| improvement | 🆙 improvement                 | 对现有特性的提升                                        |
| perf        | 📈  perf                       | 性能提升                                                |
| refactor    | 🛠 refactor                    | 代码重构，注意和特性、重构区分开                        |
| revert      | ⏪  revert                     | 回退版本                                                |
| style       | 💅  style                      | 修改格式，不影响功能，例如空格、代码格式等 清理无用代码 |
| test        | 🏁  test                       | 修改或添加测试文件                                      |
| WIP         | 🚧  WIP                        | 开发中                                                  |

- 作用域

作用域可以是任何指定提交更改位置的内容；如果不想添加，填写默认的 main 即可。

建议是和 epic 关键词关联

- 是否包含破坏性变更

<类型>(范围) 后面有一个 ! 的提交，表示引入了破坏性 API 变更。 破坏性变更可以是任意 类型 提交的一部分。

如果选择了此部分，那么脚注中必须增加对应的破坏性变更的内容

- 主题

主题包括了对本次修改的简洁描述，有以下准则

1. 使用命令式，现在时态：“改变”不是“已改变”也不是“改变了”
2. 不要大写首字母
3. 不在末尾添加句号

- Jira issue id

以 # 号隔开提交主题，以逗号区分多个任务，注意不使用空格分隔

但建议是一个提交只关联一个任务

```text
# AIOS-11,BCSC-431
```

### （2）正文部分-Body

可选，表达自己的修改内容即可

注意格式为加上两个空格，一行为一条内容，每行前加上序号

该部分的内容需要与页眉和页脚之间用空格隔开

例如：

```text
1. fix some bug
2. add some files to repository
```

### （3）页脚部分-Footer

该部分也是可选的

- Refs

关联的其他 commit 或 merge request，适合于以下场景

（1）同一 Jira 工作项在两个仓库中进行的场景

（2）revert 类型，和一个指向被还原提交摘要的脚注

```text
Refs: deploy/bigdeploy!412, deploy/bigdeploy@9ae5ee59
```

- BREAKING CHANGE

如果包含了破坏性提交，请描述

```text
BREAKING CHANGE: use JavaScript features not available in Node 6.
```

## 示例提交

只有页眉

```text
feat(main)!: support for parallel packaging # BCSC-431
```

不带正文，但有页脚

```text
feat(main)!: support for parallel packaging # BCSC-431
 
Refs: deploy/bigdeploy!412, deploy/bigdeploy@9ae5ee59
```

包含破坏性变更

```text
feat(main)!: support for parallel packaging # BCSC-431
  
  1. change dind to podman
  2. use subpathexprt to split pod persistent directory
  
Refs: deploy/bigdeploy!412, deploy/bigdeploy@9ae5ee59
BREAKING CHANGE: use JavaScript features not available in Node 6.
```
