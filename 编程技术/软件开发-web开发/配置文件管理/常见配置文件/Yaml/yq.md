
## 简介

yq 是一个轻量级的便携式命令行 YAML 处理器。该工具的目标是成为 yaml 文件处理方面的 jq 或 sed。

源码仓库：<https://github.com/mikefarah/yq>

## 安装方式

```bash
wget https://github.com/mikefarah/yq/releases/download/v4.27.5/yq_linux_amd64 -O /usr/bin/yq
chmod +x /usr/bin/yq
```

<https://zhuanlan.zhihu.com/p/425933574>



```bash
all_images=$(yq eval "
    .[][][]
    | [
        \"${BQDEVOPS_3RDPARTY_REPO}\" + \"/\" + (. | path | .[-3]) + \"/\" + (. | path |.[-2]) + \":\" + .
    ]
" "${IMAGES_ARCHIVE_FILE}")

```



```bash
    yq -i "
        .\"${imageRegistry}\".\"${imageRepo}\" = (
            .\"${imageRegistry}\".\"${imageRepo}\" + [\"${imageTag}\"]
            | unique
        )" "${IMAGES_ARCHIVE_FILE}"

```



```bash
yq -i '.appVersion = strenv(nextChartVer)' Chart.yaml  
```



https://www.cnblogs.com/tylerzhou/p/11050954.html
