代码结构

```
ui                    前端代码 
web_server            后端服务，所有请求入口
apiserver             接口层, 这一层是系统的 api 服务网关
scene_server          业务场景模块，基于资源管理对应用场景的封装
     admin_server       把配置文件放入 zk
     event_server       事件订阅
     host_server        主机
     topo_server        模型, 实例, 业务, 模块等
     proc_server        进程
source_controller     源管理模块, 把资源类型进行了抽象, 每一类资源由一类微服务进程来管理
     cacheservice       审计
     coreservice        主机
storage               提供系统所需的资源存储等系统服务
apimachinery          根据要操作的资源生成新的 URL, 调用 source_controller
```

资源名称：

``` 
biz:  业务线
set：集群
module：模块
host：主机
```

字段描述：

```
bk_supplier_id :供应商ID  默认为0 ，不做变动
bk_host_id  :   主机id
bk_obj_id.  :   模型id, 模型的唯一标识，如，szone，redis，set，module
```

关键词：

```
association 关联类型
object_association模型关联
inst_association   实例关联
privilege        权限
inst            模型实例
object         对象：如 module，set等
classification    模型分类
custom_query：userapi  自定义api
favorites       主机收藏
```

请求执行过程

```
api_server
1  http   --->   api_server(网关)  
 
2 api_server(网关)   -->  scene_server下的xxServer/service/service.go文件中
 
scene_server
3  service.go文件接收路由并调用响应的方法A
 
4  方法A处理逻辑包括验证头信息请求参数，最后调用apimachinery
 
apimachinery
5 在apimachinery中会生成一个新的URL 并根据这个URL向source_controller发起请求
 
source_controller
6 source_controller/XXcontroller/service/service.go接收请求 并调用响应方法B
 
storage
7  B方法调用了storage中的方法
```

配置文件生成

```
configcenter/src/bin/build/x.x.x/cmdb_adminserver/configures/*
```

数据库设计

| 表名                   | 关联业务                                                     | 备注                                               |
| ---------------------- | ------------------------------------------------------------ | -------------------------------------------------- |
| cc_ApplicationBase     | 基础资源-业务信息存储                                        |                                                    |
| cc_AsstDes             | 模型管理-关联类型数据存储                                    |                                                    |
| cc_History             | -                                                            |                                                    |
| cc_HostBase            | 基础资源-主机数据存储                                        |                                                    |
| cc_HostFavourite       | -                                                            |                                                    |
| cc_idgenerator         | 生成ID的，记录每种记录最大的ID,类似mysql 主键的auto_increment |                                                    |
| cc_InsAsst             | -                                                            |                                                    |
| cc_ModuleBase          | 业务资源-业务拓扑中的叶子节点数据                            |                                                    |
| cc_ModuleHostConfig    | 主机分配到具体业务模块表，bk_module_id是cc_ModuleBase.bk_module_id |                                                    |
| cc_Netcollect_Device   | -                                                            |                                                    |
| cc_Netcollect_Property | -                                                            |                                                    |
| cc_ObjAsst             | 模型与模型之间的关联关系,见模型管理-模型拓扑                 |                                                    |
| cc_ObjAttDes           | 模型的所有字段                                               |                                                    |
| cc_ObjClassification   | 存储模型分组数据，针对模型管理-新建分组业务                  |                                                    |
| cc_ObjDes              | 存储模型数据，针对模型管理-模型-新建模型业务                 |                                                    |
| cc_ObjectBase          | 自定义模型的实例                                             |                                                    |
| cc_ObjectUnique        | -                                                            |                                                    |
| cc_UserGroupPrivilege  | 当添加用户权限的时候， 表里面才显示数据                      | 通过group_id字段关联                               |
| cc_UserGroup           | 添加用户权限管理                                             |                                                    |
| cc_UserCustom          | 用户自定义收藏模块                                           | index_v4_recently 存储最近添加唯一标识             |
| cc_UserAPI             | -                                                            |                                                    |
| cc_TopoGraphics        | 存储模块在拓扑图中的位置  用户删除位置，数据表还是保留当前字段，位置置空 |                                                    |
| cc_System              | 系统                                                         |                                                    |
| cc_Subscription        | 事件推送                                                     |                                                    |
| cc_SetBase             | 业务资源-> 业务拓扑                                          |                                                    |
| cc_PropertyGroup       |                                                              |                                                    |
| cc_Process             | 业务资源-> 进程管理 存储进程                                 | bk_biz_id 对应 cc_ApplicationBase  表中的bk_biz_id |
| cc_ProcOpTask          | -                                                            |                                                    |
| cc_ProcInstanceModel   | -                                                            |                                                    |
| cc_ProcInstanceDetail  | -                                                            |                                                    |
| cc_Proc2Module         | -                                                            |                                                    |
| cc_Privilege           | -                                                            |                                                    |
| cc_PlatBase            | -                                                            |                                                    |

## 参考文档

- <https://www.cnblogs.com/hhxylm/p/11579123.html>