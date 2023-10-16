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

## Rails Console

开启 Rails Console

```bash
gitlab-rails console
```

### 重置密码

超级管理员用户默认都是 1

```ruby
user = User.where(id:1).first
```

输入`user.password='密码'`，密码位置填写您新的密码即可。然后再输入`user.save!` 保存用户对象

```ruby
user.password='abcd1234!'
user.save!
```

