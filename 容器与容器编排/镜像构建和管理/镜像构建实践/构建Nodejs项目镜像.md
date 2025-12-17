## 简介

编译构建服务打包 Node.js 项目及制作构建包的 Docker 镜像

官方文档：

- 把一个 Node.js web 应用程序给 Docker 化 <https://nodejs.org/zh-cn/docs/guides/nodejs-docker-webapp/>

### 基础镜像

`node:<version>`：这是官方默认镜像，基于 debian 构建，可指定的版本有：

- Debian 10（buster） — 当前的稳定版（stable）
- Debian 9（stretch） — 旧的稳定版（oldstable）
- Debian 8（jessie） — 更旧的稳定版（oldoldstable）
- Debian 7（wheezy） — 被淘汰的稳定版

这些镜像是基于 buildpack-deps（<https://hub.docker.com/_/buildpack-deps/>） 进行构建的，此类镜像的优点是安装的依赖很全，例如 `curl`、`wget` ，缺点是体积过大。

`node:<version>-slim` ：这是删除冗余依赖后的精简版本镜像，同样是基于 debian 构建，体积上比默认镜像小很多，删除了很多公共的软件包，只保留了最基本的 node 运行环境。

`node:<version>-alpine`：这个版本基于 alpine 镜像构建，比 debian 的 slim 版本还要小，可以说是最小的 node 镜像。虽然体积小，但是功能不少，普通的 node.js 应用都能跑起来，但是如果项目中用到了 c++ 扩展的话，因为 alpine 使用 musl 代替 glibc，一些 c/c++ 环境的软件可能不兼容。

官方：

- `docker.io` 中提供的基础镜像： <https://hub.docker.com/_/node>

- Nodejs 镜像构建源码：<https://github.com/nodejs/docker-node>

## 示例

### 创建 Node.js 应用

首先，创建一个新文件夹以便于容纳需要的所有文件，并且在此其中创建一个 `package.json` 文件，描述你应用程序以及需要的依赖：

```json
{
    "name": "docker_web_app",
    "version": "1.0.0",
    "description": "Node.js on Docker",
    "author": "First Last <first.last@example.com>",
    "main": "server.js",
    "scripts": {
        "start": "node server.js"
    },
    "dependencies": {
        "express": "^4.16.1"
    }
}
```

配合着你的 `package.json` 请运行 `npm install`。

如果你使用的 `npm` 是版本 5 或者之后的版本，这会自动生成一个 `package-lock.json` 文件，它将一起被拷贝进入你的 Docker 镜像中。

然后，创建一个 `server.js` 文件，使用 `Express.js` 框架定义一个 Web 应用：

```js
'use strict';

const express = require('express');

// Constants
const PORT = 8080;
const HOST = '0.0.0.0';

// App
const app = express();
app.get('/', (req, res) => {
    res.send('Hello World');
});

app.listen(PORT, HOST, () => {
    console.log(`Running on http://${HOST}:${PORT}`);
});

```

### 构建镜像

注意：

- 只是拷贝了 `package.json` 文件而非整个工作目录。这允许利用缓存 Docker 层的优势

```dockerfile
FROM node:16.19.1-slim

# Create app directory
WORKDIR /usr/src/app

# Install app dependencies
# A wildcard is used to ensure both package.json AND package-lock.json are copied
# where available (npm@5+)
COPY package*.json ./

RUN npm install
# If you are building your code for production
# RUN npm ci --only=production

# Bundle app source
COPY . .

EXPOSE 8080
CMD [ "node", "server.js" ]
```

### .dockerignore 文件

在 `Dockerfile` 的同一个文件夹中创建一个 `.dockerignore` 文件，带有以下内容：

```lua
node_modules
npm-debug.log
```

这将避免你的本地模块以及调试日志被拷贝进入到你的 Docker 镜像中，以至于把你镜像原有安装的模块给覆盖了。

## 其他参考

安装 NVM

```dockerfile
# install - nvm
ENV \
    NODE_MIRROR=https://mirrors.tuna.tsinghua.edu.cn/nodejs-release/ \
    NVM_DIR="/opt/nvm"

ARG INST_NVM_VESION=v0.39.3

RUN --mount=type=cache,target=/var/cache,id=build-cache \
    --mount=type=cache,target=/tmp,id=build-tmp \
    \
    mkdir -p ${NVM_DIR} \
    && curl -fsSL https://raw.githubusercontent.com/nvm-sh/nvm/${INST_NVM_VESION}/install.sh | bash
```

使用 nvm 管理多个版本的 nodejs

```dockerfile
# install - nvm and nodejs
ARG INST_NODE_VERSION=v16.19.0

RUN --mount=type=cache,target=/var/cache,id=build-cache \
    --mount=type=cache,target=/tmp,id=build-tmp \
    <<EOF
#!/usr/bin/env bash

# set -o nounset
set -o errexit


[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

nvm install "${INST_NODE_VERSION}" > /dev/null
nvm cache clear
nvm use "${INST_NODE_VERSION}"

export NPM_CONFIG_CMD=( "npm" "config" "set" )

"${NPM_CONFIG_CMD[@]}" strict-ssl false
"${NPM_CONFIG_CMD[@]}" cache /var/cache/npm
# "${NPM_CONFIG_CMD[@]}" registry xxx
# "${NPM_CONFIG_CMD[@]}" sass_binary_site xxx
# "${NPM_CONFIG_CMD[@]}" phantomjs_cdnurl xxx
# "${NPM_CONFIG_CMD[@]}" electron_mirror xxx
# "${NPM_CONFIG_CMD[@]}" sqlite3_binary_host_mirror xxx
# "${NPM_CONFIG_CMD[@]}" profiler_binary_host_mirror xxx
# "${NPM_CONFIG_CMD[@]}" chromedriver_cdnurl xxx

# install tools
export NPM_INSTALL_CMD=( "npm" "install" "--global")

"${NPM_INSTALL_CMD[@]}" yarn

export YARN_CONFIG_CMD=( "yarn" "config" "set")

"${YARN_CONFIG_CMD[@]}" strict-ssl false
"${YARN_CONFIG_CMD[@]}" cache /var/cache/yarn
# "${YARN_CONFIG_CMD[@]}" registry xxx
# "${YARN_CONFIG_CMD[@]}" sass_binary_site xxx
# "${YARN_CONFIG_CMD[@]}" phantomjs_cdnurl xxx
# "${YARN_CONFIG_CMD[@]}" electron_mirror xxx
# "${YARN_CONFIG_CMD[@]}" sqlite3_binary_host_mirror xxx
# "${YARN_CONFIG_CMD[@]}" profiler_binary_host_mirror xxx
# "${YARN_CONFIG_CMD[@]}" chromedriver_cdnurl xxx

EOF
```

nodejs 常用的工具

```bash
# pm2, refer: https://pm2.keymetrics.io/
yarn install pm2 -g

# next.js, refer: https://nextjs.org/
yarn install next -g
```

