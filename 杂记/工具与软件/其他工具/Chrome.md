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
