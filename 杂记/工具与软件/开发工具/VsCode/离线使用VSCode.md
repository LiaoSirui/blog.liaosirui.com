需压使用的站点：<https://code.visualstudio.com/docs/setup/network#_common-hostnames>

<https://code.visualstudio.com/docs/remote/faq#_what-are-the-connectivity-requirements-for-vs-code-server>

设置本地下载扩展

```json
{
     "remote.downloadDependenciesLocally": true // defaults to false
}
```

设置本地下载 VSCode-Server

```json
{
  "remote.SSH.allowLocalServerDownload": true,
  "remote.SSH.localServerDownload": "always",
}
```

下载镜像

```json
{
   "remote.downloadDependencyMirror": "https://somehostname.com/somedir/" 
   // https://update.code.visualstudio.com/commit:$COMMIT_ID$/server-linux-x64/stable 
   // https://update.code.visualstudio.com/commit:863d2581ecda6849923a2118d93a088b0745d9d6/server-linux-x64/stable
   // expected call https://somehostname.com/somedir/863d2581ecda6849923a2118d93a088b0745d9d6/server-linux-x64/stable
}
```



CLI 下载

```
	https://update.code.visualstudio.com/commit:863d2581ecda6849923a2118d93a088b0745d9d6/cli-linux-x64/stable
```

