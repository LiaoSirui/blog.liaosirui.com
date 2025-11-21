官方 API 接口文档 <https://help.sonatype.com/en/rest-and-integration-api.html#rest-and-integration-api>

验证使用`"Authorization": "Basic xxx"`请求头信息

`xxx` 使用 `username:password` 的 Base64 值

- Nexus Blob 管理
  - `POST /v1/blobstores/file` Create a file blob store
  - `GET /v1/blobstores/file/{name}` Get a file blob store configuration by name

- Nexus 仓库管理 
  - `GET /v1/repositorySettings` List repositories
  - `GET /v1/repositories` List repositories
  - 仓库类型不一样，其接口也不同（以 yum proxy 为例）
    - `POST /v1/repositories/yum/proxy` Create Yum hosted repository
    - `GET /v1/repositories/yum/proxy/{repositoryName}` Get repository
    - `PUT /v1/repositories/yum/proxy/{repositoryName}` Update Yum hosted repository

这里以创建 yum proxy 仓库为例

```json
{
  # 仓库的名称，建议用英文名称
  "name": "internal",
  # 仓库是否在线可用
  "online": true,
  # 对象存储相关
  "storage": {
    "blobStoreName": "default",
    "strictContentTypeValidation": true
  },
  # 清理规则，没有定义规则可以删除这个属性
  "cleanup": {
    "policyNames": [
      "string"
    ]
  },
  # 代理相关
  # remoteUrl是需要代理的远程仓库地址
  "proxy": {
    "remoteUrl": "https://remote.repository.com",
    "contentMaxAge": 1440,
    "metadataMaxAge": 1440
  },
  # 缓存代理仓库中不存在的内容的响应
  "negativeCache": {
    "enabled": true,
    "timeToLive": 1440
  },
  # http 客户端相关
  "httpClient": {
    "blocked": false,
    "autoBlock": true,
    # 连接相关，如重试、超时之类，默认可以不开启
    "connection": {
      "retries": 0,
      "userAgentSuffix": "string",
      "timeout": 60,
      "enableCircularRedirects": false,
      "enableCookies": false,
      "useTrustStore": false
    },
    # 远程代理仓库如果需要认证的话，可以设置以下认证信息
    "authentication": {
      "type": "username",
      "username": "string",
      "password": "string",
      "ntlmHost": "string",
      "ntlmDomain": "string"
    }
  },
  # 路由规则，可以设置路由黑名单、白名单之类的规则
  "routingRule": "string",
  # 复制相关设置，在页面上没找到相关配置
  "replication": {
    "preemptivePullEnabled": false,
    "assetPathRegex": "string"
  },
  # yum 签名，可以忽略
  "yumSigning": {
    "keypair": "string",
    "passphrase": "string"
  }
}
```

