## 部署 Nexus

初始化密码

目前的 Nexus3 用户名 admin 的初始化密码不再是 admin123，需要在文件中去查看密码。

```
docker compose exec -it nexus cat /opt/sonatype/sonatype-work/nexus3/admin.password
```

输出后的密码是一个 uuid，这个就是密码，不要考虑太多，直接全部复制去登陆。登录成功后会有个提示修改密码的操作，修改密码就可以了。

修改密码后一定要记住，在修改密码完成之后 admin.password ⽂件会⾃动删除。

## Nexus 报 Detected content type 错误问题处理

这是由于 Nexus 会去校验仓库内容是否是适用于存储库格式的 MIME 类型，这里在仓库设置中取消校验设置即可：如下图

![请输入图片描述](./.assets/Nexus部署和运维/1001189214.png)