## GitLab 常用命令

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

输入`user.password='密码'`，密码位置填写新的密码即可。然后再输入`user.save!` 保存用户对象

```ruby
user.password='abcd1234!'
user.save!
```

### 配置

关闭注册

```bash
::Gitlab::CurrentSettings.update!(signup_enabled: false)
```

设置管理员

```bash
user = User.find_by(username: 'sirui.liao')

user.admin = true
user.save!
```

## 仓库和 hash 对应

Gitlab 的仓库存放在 `@hashed` 目录中

对应方式：

```bash
echo -n $ID | sha256sum
```

## 邮箱配置

- <https://gitlab.cn/docs/omnibus/settings/smtp.html>
- <https://docs.gitlab.com/omnibus/settings/smtp/>

## 参考资料

- GitLab 全局搜索之 SourceGraph <https://wiki.eryajf.net/pages/042695/#_4-%E5%B0%8F%E7%BB%93>

- <https://guoxudong.io/post/gitlab-beautify-issue/>

- <https://docs.authing.cn/v2/integration/gitlab/?step=2>

- <https://todoit.tech/k8s/gitlab-ci/>
- <https://www.qikqiak.com/k8s-book/docs/65.Gitlab%20CI.html>

- <https://zj-git-guide.readthedocs.io/zh-cn/latest/platform/%5BGitLab%5D%E5%AE%89%E8%A3%85/>



github 主页美化

- <https://zj-git-guide.readthedocs.io/zh-cn/latest/platform/%5BGithub%5D%E4%B8%BB%E9%A1%B5%E7%BE%8E%E5%8C%96/>

- <https://cloud.tencent.com/developer/article/2118691>
