## GitHub Actions

GitHub Actions 是一种持续集成和持续交付 (CI/CD) 平台，可用于自动执行生成、测试和部署管道

官方文档：

- <https://github.com/features/actions>

- <https://docs.github.com/zh/actions/learn-github-actions/understanding-github-actions>

官方市场：<https://github.com/marketplace?type=actions>

参考：

- <https://github.com/sdras/awesome-actions>

## 基本概念

- workflow （工作流程）：持续集成一次运行的过程，就是一个 workflow

- job （任务）：一个 workflow 由一个或多个 jobs 构成，含义是一次持续集成的运行，可以完成多个任务

- step（步骤）：每个 job 由多个 step 构成，一步步完成

- action （动作）：每个 step 可以依次执行一个或多个命令（action）

### workflow 文件

GitHub Actions 的配置文件叫做 workflow 文件，存放在代码仓库的 `.github/workflows` 目录

workflow 文件采用 YAML 格式，文件名可以任意取，但是后缀名统一为 `.yml`，比如`foo.yml`

一个库可以有多个 workflow 文件，GitHub 只要发现 `.github/workflows` 目录里面有 `.yml` 文件，就会自动运行该文件

下面是一个完整的 workflow 文件的范例

```yaml
name: Greeting from Mona
on: push

jobs:
  my-job:
    name: My Job
    runs-on: ubuntu-latest
    steps:
    - name: Print a greeting
      env:
        MY_VAR: Hi there! My name is
        FIRST_NAME: Mona
        MIDDLE_NAME: The
        LAST_NAME: Octocat
      run: |
        echo $MY_VAR $FIRST_NAME $MIDDLE_NAME $LAST_NAME.
```

