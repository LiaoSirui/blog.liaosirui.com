## Skills 基本结构

一个 Skill 本质上就是一个 Markdown 文件（文件名固定为 SKILL.md）

```bash
my-skill/
└── SKILL.md
```

`SKILL.md` 基本模板:

```markdown
---
name: your-skill-name
description: 一句话描述该 Skill 的功能和使用场景
---

# Skill 名称

## 使用指引

[给 AI 的分步骤行为指引]

## 示例

[该 Skill 的具体使用示例]
```

## Skills 目录结构

一个完整的 Skill 不是单个文件，而是包含多个文件的目录。

以下是一个标准 Skill 的完整目录结构：

```bash
my-skill/
│
├── SKILL.md          ← 核心执行文件
├── metadata.json     ← 元信息
├── examples/         ← 示例目录
│   ├── example1.md
│   └── example2.md
│
├── scripts/          ← 可执行脚本
│   ├── main.py
│   └── utils.py
│
├── resources/        ← 资源目录
│   ├── prompt.md
│   └── config.yaml
│
├── tests/            ← 测试目录
│   ├── test_cases.md
│   └── eval.yaml
│
├── README.md         ← 使用说明
│
└── CHANGELOG.md      ← 变更日志
```

