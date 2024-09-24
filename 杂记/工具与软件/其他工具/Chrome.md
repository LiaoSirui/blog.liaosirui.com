## Standalone 下载

自己添加参数下载 Chrome Standalone，例如

```plain
https://www.google.cn/chrome/?standalone=1&platform=win64&extra=stablechannel
```

## 信任自签证书

- <https://www.wyr.me/post/618>

- <https://blog.csdn.net/arv002/article/details/109066228>

导出为 DER 编码二进制 X.509 格式

```plain
"C:\Program Files (x86)\Google\Chrome\Application\chrome.exe" --disable-infobars --ignore-certificate-errors

# mac
--ignore-urlfetcher-cert-requests
```

## 解决 http 强跳 https

在地址栏输入一下网址开启设定页面

在网址列输入以下网址开启设定页面

- `chrome://net-internals/#hsts`
- `edge://net-internals/#hsts`

到最下方找到 Delete domain security policies 设定，输入 localhost 按下 Delete

## 插件

- AdBlock <https://chrome.google.com/webstore/detail/gighmmpiobklfepjocnamgkkbiglidom>

- OneTab（把全部打开的标签页收起来，以供下次恢复） <https://chromewebstore.google.com/detail/onetab/chphlpgkkbolifaimnlloiipkdnihall>

- Proxy SwitchyOmega（轻松快捷地管理和切换多个代理设置）<https://chromewebstore.google.com/detail/proxy-switchyomega/padekgcemlokbadohgkifijomclgjgif>

- Vimium（Vim 快捷键）<https://chromewebstore.google.com/detail/vimium/dbepggeogbaibhgnhhndojpepiihcmeb>

- SuperCopy <https://chromewebstore.google.com/detail/supercopy-allow-right-cli/onepmapfbjohnegdmfhndpefjkppbjkm>
- Auto Group Tabs（按照域名自动分组）<https://chromewebstore.google.com/detail/auto-group-tabs/mnolhkkapjcaekdgopmfolekecfhgoob>

## Vimium 常用快捷键

- j:向下滚动
- k:向上滚动
- d:向下滚动半个页面
- u:向上滚动半个页面
- G:滚动到屏幕底部
- gg:滚动到屏幕顶部
- J:向左移动一个标签
- K:向右移动一个标签
- t:打开一个空白标签页
- ?:打开帮助
- x:关闭当前标签
- X:打开刚刚关闭的标签 = `Cmd\Ctrl + shift + t`
- f:给当前页面所有链接创建快捷键，并在当前标签打开
- F:同f，但是在新标签打开
- /:进入查找模式
- b:打开书签
- r:刷新当前页面
- yt:复制当前标签并打开
- T:显示浏览器打开的所有URL
