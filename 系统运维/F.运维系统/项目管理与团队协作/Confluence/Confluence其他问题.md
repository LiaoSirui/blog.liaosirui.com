## Confluence 文件预览乱码

假设Confluence安装目录为`/opt/atlassian/confluence`，应用数据目录为`/var/atlassian/application-data/confluence`

1. 将 windows`C:\Windows\Fonts`目录下的字体文件复制到`/opt/atlassian/confluence/fonts`目录

2. 修改`/opt/atlassian/confluence/bin/setenv.sh`文件

   ```
   # vi /opt/atlassian/confluence/bin/setenv.sh
   CATALINA_OPTS="-Dconfluence.document.conversion.fontpath=/opt/atlassian/confluence/fonts/ ${CATALINA_OPTS}"
   ```

3. 删除应用临时预览文件

   ```
   cd /var/atlassian/application-data/confluence
   rm -rf viewfile/*
   rm -rf shared-home/dcl-document/*
   rm -rf shared-home/dcl-document_hd/*
   rm -rf shared-home/dcl-thumbnail/*
   ```

   

## PDF 导出中文失败

安装 PDF 导出中文字体

![Confluence PDF导出中文支持_Confluence](./.assets/Confluence其他问题/resize,m_fixed,w_1184)

- <https://github.com/chengda/popular-font>

## 页面添加返回顶部

设置 -> 自定义HTML -> BODY尾部中添加如下代码。

```html
<script type="text/javascript">
    //<![CDATA[
    AJS.toInit(function () {
        //If the scroll button doesn't exist add it and set up the listeners
        if (AJS.$('#scroll-top').length == 0) {
            AJS.$('#main-content').prepend('<button id="scroll-top" class="aui-button aui-button-primary scroll-top-button" style="display: none; position: fixed; bottom: 10px; right: 10px; z-index: 10;" title="返回顶部"><span class="aui-icon aui-icon-small aui-iconfont-chevron-up">Back to Top</span></button>');

            //Check to see if the window is top if not then display button
            AJS.$(window).scroll(function () {
                if (AJS.$(this).scrollTop() > 100) {
                    AJS.$('#scroll-top').fadeIn();
                } else {
                    AJS.$('#scroll-top').fadeOut();
                }
            });

            //Click event to scroll to top
            AJS.$('#scroll-top').click(function () {
                AJS.$('html, body').animate({scrollTop: 0}, 500);
                return false;
            });
        }
    });
    //]]>
</script>
```

## 开启插件上传

- 开启上传插件：<https://confluence.atlassian.com/conf85/managing-system-and-marketplace-apps-1283360882.html>

```
Option 1: Re-enable the UI upload button and API

Set the system property upm.plugin.upload.enabled to true.
Perform a restart.
Upload the app through the UPM UI.
We recommend that you disable the button once your upload is complete, using the additional steps below.

Set the system property upm.plugin.upload.enabled to false,

Perform a restart.

Option 2: Load custom plugins from your Confluence file system

 If the system property atlassian.confluence.plugin.scan.directory is not set, provide the target location of your custom plugins. We recommend a directory within the Confluence home directory, such as $CONFLUENCE_HOME/plugins/installed-plugins.

Restart Confluence.
```

修改系统属性，详见：<https://confluence.atlassian.com/conf88/configuring-system-properties-1354500668.html>
