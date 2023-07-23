## 参考文档

- <https://docs.authing.cn/v2/integration/gitlab/?step=2>

- <https://todoit.tech/k8s/gitlab-ci/>
- <https://www.qikqiak.com/k8s-book/docs/65.Gitlab%20CI.html>

## gitlab 常用命令

启动所有 gitlab 组件

```bash
gitlab-ctl start
```

停止所有 gitlab 组件

```bash
gitlab-ctl stop
```

重启所有 gitlab 组件

```bash
gitlab-ctl restart
```

查看服务状态

```bash
gitlab-ctl status
```

修改 gitlab 配置文件

```bash
vim /etc/gitlab/gitlab.rb
```

重新编译 gitlab 的配置

```bash
gitlab-ctl reconfigure
```

检查 gitlab

```bash
gitlab-rake gitlab:check SANITIZE=true --trace  
```

查看日志

```bash
gitlab-ctl tail        
gitlab-ctl tail nginx/gitlab_access.log
```
