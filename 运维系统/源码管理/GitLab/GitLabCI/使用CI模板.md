## 导入模板

使用 `include` 在 CI/CD 配置中 import 外部 YAML 文件

可以将一个长的 `.gitlab-ci.yml` 文件拆分为多个文件以提高可读性，或减少同一配置在多个位置的重复

- `local`：导入位于同一仓库中的文件

- `file`：导入同一实例上另一个私有仓库的文件

```yaml
# 可以导入同一项目的多个文件
include:
  - project: 'my-group/my-project'
    ref: main
    file:
      - '/templates/.builds.yml'
      - '/templates/.tests.yml'
```

- `remote`：使用完整 URL 导入远程实例中文件

- `template`：导入 GItLab 提供的 CI Template

## 使用模板更新 Tag

### extend

使用 `extends` 来重用配置，也是将 git push 相关操作插入具体 Job 的方法。它是 YAML 锚点的替代方案，并且更加灵活和可读

文档：<https://docs.gitlab.com/ci/yaml/yaml_optimization/>

```yaml
# extend example
.tests:
  script: rake test
  stage: test
  only:
    refs:
      - branches

rspec:
  extends: .tests
  script: rake rspec
  only:
    variables:
      - $RSPEC

```

### 推送代码的模板

`before_script` 与 `after_script`

- 使用 `before_script` 可以定义一系列命令，这些命令应该在每个 Job 的 `script` 命令之前，但在 `artifacts` 恢复之后运行

- 使用 `after_script` 定义在每个作业之后运行一系列命令，需要注意的是，即使是失败的 Job 也会运行这一系列命令

可以非常方便的在 `before_script` 定义 Git 操作的预备逻辑，如：clone 代码、配置 email/username 等；而在 `after_script` 中会定义 Git 的 commit 以及 push 操作

用到的 CI 预定义变量有：

| 变量              | 说明                                     | 示例                        |
| :---------------- | :--------------------------------------- | :-------------------------- |
| CI_COMMIT_SHA     | Commit SHA，用于创建名称唯一的文件       | `e46fxxxxxx`                |
| CI_DEFAULT_BRANCH | 项目默认分支的名称                       | `main`                      |
| CI_PROJECT_PATH   | 包含项目名称的项目命名空间               | `gitlab/gitlab-cn`          |
| CI_SERVER_HOST    | GitLab 实例 URL 的主机，没有协议或端口   | `gitlab.example.com`        |
| GITLAB_USER_EMAIL | 开始作业的用户的 email                   | `xxx@alpha-quant.tech`      |
| GITLAB_USER_NAME  | 启动作业的用户的姓名                     | AlphaQuant                  |
| CI_PROJECT_DIR    | 仓库克隆到的完整路径，以及作业从哪里运行 | `/builds/gitlab/gitlab-cn/` |
| CI_COMMIT_BRANCH  | 提交分支名称                             | `feat/git_push`             |
| CI_COMMIT_MESSAGE | 完整的提交消息                           | `feat: add git push stage`  |

完成推送功能的脚本：

```yaml
.git:push:
  before_script:
    # Clone the repository via HTTPS inside a new directory
    - |
      git clone "https://${GITLAB_USERNAME}:${GITLAB_TOKEN}@${CI_SERVER_HOST}/${CI_PROJECT_PATH}.git" "${CI_COMMIT_SHA}"
      cd "${CI_COMMIT_SHA}"

    # Check out branch if it's not master
    - |
      if [[ "${CI_COMMIT_BRANCH}" != "${CI_DEFAULT_BRANCH}" ]]; then
        git fetch
        git checkout -t "origin/${CI_COMMIT_BRANCH}"
      fi

    - git branch
    # Set the displayed user with the commits that are about to be made
    - git config --global user.name "${GIT_USER_NAME:-$GITLAB_USER_NAME}"
    - git config --global user.email "${GIT_USER_EMAIL:-$GITLAB_USER_EMAIL}"

    - cd "${CI_PROJECT_DIR}"
  after_script:
    # Go to the new directory
    - cd "${CI_COMMIT_SHA}"

    # Add all generated files to Git
    - git add -A

    - |-
      # Check if we have modifications to commit
      CHANGES=$(git status --porcelain | wc -l)

      if [ "$CHANGES" -gt "0" ]; then
        # Show the status of files that are about to be created, updated or deleted
        git status

        # Commit all changes
        git commit -m "${CI_COMMIT_MESSAGE}"

        # Update the repository
        if [ "${SKIP_CI}" -gt "0" ]; then
          # Skip the pipeline create for this commit
          echo "Skip"
          git push -o ci.skip
        else
          echo "no Skip"
          git push
        fi
        echo "Over"
      else
        echo "Nothing to commit"
      fi

```

上面这个 `git-push.yaml` 中并没有 `script` 关键字，也就是说，这个 Job 是不能单独运行的，需要将其 `incloud` 到您的 `.gitlab-ci.yml` 并且 `extends` 到相关 Job，效果如下：

```yaml
#.gitlab-ci.yml
include:
  - local: .gitlab/ci/docs-git-push.yaml

...
Git push:
  stage: deploy
  extends:
    - .git:push
  script:
    - |
      # Move some generated files
      mv dist/* "${CI_COMMIT_SHA}"
...

```

运行 CI 前还需要插入 `GITLAB_TOKEN` 和 `GITLAB_USERNAME`

个人访问令牌时，需要勾选以下范围：

- `read_repository`
- `write_repository`
