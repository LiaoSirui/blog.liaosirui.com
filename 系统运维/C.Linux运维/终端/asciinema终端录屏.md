## asciinema 简介

终端录屏工具 asciinema 是一个免费和开源的解决方案，用于记录终端会话并在网上分享。它支持在终端内直接录制，提供播放、复制粘贴和嵌入功能。安装方面，支持多种操作系统，包括 Linux、MacOS 和 FreeBSD。使用上，通过命令行界面即可轻松录制、播放和分享终端会话

此外，asciinema 还支持自托管服务器，允许用户完全掌控录制内容。对于不支持 `<script>` 标签的网站，还可以通过动画 GIF 文件来嵌入演示

官方：

- 官网：<https://asciinema.org/>
- <https://github.com/asciinema/asciinema>
- 播放器：<https://github.com/asciinema/asciinema-player>
- 自托管服务器：<https://github.com/asciinema/asciinema-server>
- GIF 转换器：<https://github.com/asciinema/agg>

安装

```bash
# Using pipx
pipx install asciinema

# RHEL
dnf install asciinema

# macos
brew install asciinema
```

## 使用 asciinema

（1）输入以下命令开始记录

```bash
asciinema rec demo.cast
```

这将启动一个新的录制会话。在此会话期间，终端中显示的所有内容都将被捕捉并保存为 asciicast 格式的 `demo.cast` 文件

想结束录制会话时，退出 shell 即可。这可以通过按 `ctrl+d` 或输入 `exit` 命令来实现

（2）重放 Replay

通过以下命令回放录制内容

```bash
asciinema play demo.cast
```

播放过程中，可以按空格键暂停或恢复，或按 `ctrl+c` 提前结束播放。暂停的时候可以直接复制视频中的内容

（3）分享

可以在 asciinema.org 上托管录制内容，这是一个由 asciinema 服务器支持的终端录制专用托管平台。虽然将录制内容托管在 asciinema.org 上是可选的，但这会带来许多便利，如轻松分享和嵌入。

使用以下命令将录制内容上传到 asciinema.org：

```bash
asciinema upload demo.cast
```

（4）嵌入 Embedding

asciinema 播放器可以通过在网页中嵌入 HTML `<script>` 标签来在任何网站上使用。这种嵌入的播放器常被用于博客文章、项目文档和会议演讲的幻灯片中。

上传到 asciinema.org 的所有录制内容都可以通过使用在录制页面上提供的脚本片段来嵌入到网站

如果不想依赖 asciinema.org 来嵌入演示，可以在网站上这样使用独立的播放器

```html
<!DOCTYPE html>
<html>
<head>
  ...
  <link rel="stylesheet" type="text/css" href="/asciinema-player.css" />
  ...
</head>
<body>
  ...
  <div id="demo"></div>
  ...
  <script src="/asciinema-player.min.js"></script>
  <script>
    AsciinemaPlayer.create('/demo.cast', document.getElementById('demo'));
  </script>
</body>
</html>
```

## 自托管服务器

asciinema.org 是 CLI 用于上传录制内容的默认 asciinema 服务器，但如果希望完全掌控录制内容，可以选择自行托管服务器实例

```yaml
services:
  asciinema:
    image: ghcr.io/asciinema/asciinema-server:20240428
    ports:
      - '80:4000'
    environment:
      - SECRET_KEY_BASE=  # <- see below
      - URL_HOST=asciinema.example.com
      - URL_PORT=80
      - SMTP_HOST=smtp.example.com
      - SMTP_USERNAME=foobar
      - SMTP_PASSWORD=hunter2
    volumes:
      - asciinema_data:/var/opt/asciinema
    depends_on:
      postgres:
        condition: service_healthy

  postgres:
    image: docker.io/library/postgres:14
    environment:
      - POSTGRES_HOST_AUTH_METHOD=trust
    volumes:
      - postgres_data:/var/lib/postgresql/data
    healthcheck:
      test: ['CMD-SHELL', 'pg_isready -U postgres']
      interval: 2s
      timeout: 5s
      retries: 10

volumes:
  asciinema_data:
  postgres_data:
```

录制上传

```bash
export ASCIINEMA_API_URL=http://localhost:4000

asciinema rec demo.cast
asciinema upload demo.cast
```

## 生成 GIF

使用 agg 工具从录制文件创建 GIF：

```bash
agg demo.cast first.gif
```

使用 asciinema 播放器展示录制内容通常比使用 GIF 文件更佳。与 GIF 相比，播放器支持暂停、回放、复制文本，并且始终能够以最佳清晰度显示终端内容