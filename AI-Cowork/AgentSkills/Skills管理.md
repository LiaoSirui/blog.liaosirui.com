- <https://github.com/anthropics/skills>

- <https://github.com/ComposioHQ/awesome-claude-skills>

- <https://www.skills.sh/>
- <https://github.com/obra/superpowers>

## 自维护 skill repo

推荐将所有团队 Skill 放在同一个 Git 仓库中，用目录隔离不同 Skill。

```plain
skills-repo/
├── README.md                  # 仓库总览，列出所有 Skill
├── .github/
│   └── workflows/
│       └── package.yml        # CI：自动打包 .skill 文件
├── skills/
│   ├── data-analyzer/         # Skill 1
│   │   ├── SKILL.md
│   │   └── scripts/
│   ├── doc-generator/         # Skill 2
│   │   ├── SKILL.md
│   │   └── scripts/
│   └── code-reviewer/         # Skill 3
│       ├── SKILL.md
│       └── scripts/
├── dist/                      # 打包好的 .skill 文件
│   ├── data-analyzer.skill
│   ├── doc-generator.skill
│   └── code-reviewer.skill
└── tools/
    └── build_all.sh           # 批量打包脚本
```

