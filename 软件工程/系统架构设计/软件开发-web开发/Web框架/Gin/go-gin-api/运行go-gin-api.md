构建一个完整的 gin 项目：`go-gin-api`

官方仓库地址：<https://github.com/xinliangnote/go-gin-api>

支持的功能：

- 支持 rate 接口限流
- 支持 panic 异常时邮件通知
- 支持 cors 接口跨域
- 支持 Prometheus 指标记录
- 支持 Swagger 接口文档生成
- 支持 GraphQL 查询语言
- 支持 trace 项目内部链路追踪
- 支持 pprof 性能剖析
- 支持 errno 统一定义错误码
- 支持 zap 日志收集
- 支持 viper 配置文件解析
- 支持 gorm 数据库组件
- 支持 go-redis 组件
- 支持 RESTful API 返回值规范
- 支持 生成数据表 CURD、控制器方法 等代码生成器
- 支持 cron 定时任务，在后台可界面配置
- 支持 websocket 实时通讯，在后台有界面演示
- 支持 web 界面，使用的 Light Year Admin 模板

运行项目

```bash
git clone https://github.com/xinliangnote/go-gin-api.git

cd go-gin-api

go run main.go -env dev 
```

运行 MySQL 和 Redis 即可

```bash
docker run --name mysql-bear -p 3307:3306 -e MYSQL_ROOT_PASSWORD=mysql-bear -d mysql:latest
docker run --name redis-bear -p 6479:6379 -d redis
```

项目要求先建库

```bash
docker exec -it mysql-bear mysql -pmysql-bear -e "create database bear_gin_db CHARACTER SET utf8 COLLATE utf8_general_ci;"
```

点击初始化项目，在本地重启项目