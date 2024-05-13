`/usr/lib/code-server/lib/vscode/product.json`

原来的源

```json
  "extensionsGallery": {
    "serviceUrl": "https://marketplace.visualstudio.com/_apis/public/gallery",
    "cacheUrl": "https://vscode.blob.core.windows.net/gallery/index",
    "itemUrl": "https://marketplace.visualstudio.com/items",
    "controlUrl": "",
    "recommendationsUrl": ""
  }

```

替换后：

```bash
export EXTENSIONS_GALLERY='{"serviceUrl":"https://<domain>/api", "itemUrl":"https://<domain>/item", "resourceUrlTemplate": "https://<domain>/files/{publisher}/{name}/{version}/{path}"}'
```

设置界面中，找到`Extensions`选项，点击进入其设置页面。在此页面中，你可以看到一个扩展商店的地址，这就是VSCode用来下载扩展的地址。将其修改为你之前获取的国内镜像源地址

```json
// open-vsx.org提供的服务
{
    extensionsGallery: {
        serviceUrl: "https://open-vsx.org/vscode/gallery",
        itemUrl: "https://open-vsx.org/vscode/item",
        resourceUrlTemplate: "https://open-vsx.org/vscode/asset/{publisher}/{name}/{version}/Microsoft.VisualStudio.Code.WebResources/{path}",
        controlUrl: "",
        recommendationsUrl: ""
    },
}
```

