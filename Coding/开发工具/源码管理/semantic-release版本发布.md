## Semantic Release

Semantic Release 是一个自动化版本发布的工具，它可以根据提交的信息自动确定下一个版本号

此特定的仓库 <https://github.com/semantic-release/gitlab.git> 是 Semantic Release 针对 GitLab 平台的插件实现，使得在使用 GitLab CI/CD 时也能享受到自动化版本管理的便利。

安装

```bash
npm install @semantic-release/gitlab -D
```

## 语义化版本

语义化版本控制规范（SemVer）是为软件版本号赋予明确含义的标准格式。其版本号采用 `X.Y.Z`（`主版本号.次版本号.修订号`）结构，通过数字变化反映代码变更性质：

- 主版本号（X）：不兼容的API重大变更时递增，次版本和修订号归零（如 2.1.3→3.0.0）
- 次版本号（Y）：向下兼容的功能新增时递增，修订号归零（如 1.2.3→1.3.0）
- 修订号（Z）：向下兼容的问题修复时递增（如 1.2.3→1.2.4）

先行版本可通过附加连字符和标识符表示（如 1.0.0-alpha.1）。版本比较按数值逐级对比，1.9.0 <1.10.0 < 2.0.0。该规范强调公共 API 的明确定义，要求维护版本更新日志，旨在通过标准化的版本号传递兼容性信息，帮助开发者管理依赖关系，避免” 依赖地狱”。遵循 SemVer 可提升软件生态系统的可预测性和协作效率，尤其适用于依赖包管理场景

Semantic Versioning 2.0.0 文档：<https://semver.org/>

## 项目的配置文件

在使用 Semantic Release 时，用户会在项目根目录下创建一个 `semantic-release.config.js`文件来定制化配置。这个配置文件可以设置 GitLab 的访问令牌、发布渠道等参数。示例如下：

```js
module.exports = {
    /* 配置项 */
    gitlab: {
        apiUrl: 'https://gitlab.example.com/api/v4', // 如果使用自托管GitLab，则需指定API地址
        token: process.env.GITLAB_TOKEN, // GitLab的访问令牌
    },
    repositoryUrl: 'https://github.com/user/repo.git', // 你的仓库URL
    /* 更多自定义配置 */
};
```

也可以通过环境变量或`.env`文件来提供必要的认证信息，确保 Semantic Release 能够正确地与 GitLab 交互并完成版本发布任务

CI 中运行

```bash
npx semantic-release
```

