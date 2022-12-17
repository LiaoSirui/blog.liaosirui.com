
将镜像从 registry 中同步到本地目录，使用 registry 存储的特性，将本地目录中的镜像转换成 registry 存储的格式， 这样的好处就是可以去除一些 skopeo dir 中重复的 layers，减少镜像的总大小

此种方式是有些复杂对于大镜像的复制是推荐的, 而对于一些小镜像且显得多余

给定一个镜像列表 images-list.txt，其格式如下：

```text
kubesphere/kube-apiserver:v1.20.6
kubesphere/kube-scheduler:v1.20.6
kubesphere/kube-proxy:v1.20.6
kubesphere/kube-controller-manager:v1.20.6
kubesphere/kube-apiserver:v1.19.8
```

- convert-images.sh

```bash
#!/bin/bash

set -eo pipefail

GREEN_COL="\\033[32;1m"
RED_COL="\\033[1;31m"
NORMAL_COL="\\033[0;39m"

BASE_PATH=$(cd "$(dirname $0)" && pwd)

SOURCE_REGISTRY=$1
IMAGES_DIR=$2

: "${IMAGES_DIR:="images"}"
: "${IMAGES_LIST_FILE:="${BASE_PATH}/images-list.txt"}"
: "${SOURCE_REGISTRY:="docker.io"}"

# 仓库服务器中的目录
BLOBS_PATH="docker/registry/v2/blobs/sha256"
REPO_PATH="docker/registry/v2/repositories"

# 记录当前数和总镜像数
CURRENT_NUM=0
ALL_IMAGES=$(sed -n '/#/d;s/:/:/p' "${IMAGES_LIST_FILE}" | sort -u)
TOTAL_NUMS=$(echo "${ALL_IMAGES}" | wc -l)

# 从远程仓库同步指定镜像到本地目录中
skopeo_sync() {
    if skopeo sync \
        --insecure-policy --src-tls-verify=false --dest-tls-verify=false \
        --override-arch amd64 --override-os linux \
        --src docker --dest dir \
        "$1" "$2" > /dev/null; then
        echo -e "$GREEN_COL Progress: ${CURRENT_NUM}/${TOTAL_NUMS} sync $1 to $2 successful $NORMAL_COL"
    else
        echo -e "$RED_COL Progress: ${CURRENT_NUM}/${TOTAL_NUMS} sync $1 to $2 failed $NORMAL_COL"
        exit 2
    fi
}

convert_images() {
    rm -rf ${IMAGES_DIR}; mkdir -p ${IMAGES_DIR}
    for image in ${ALL_IMAGES}; do
        (( CURRENT_NUM="${CURRENT_NUM}"+1 ))

        # 取 images-list.txt 文本中的每一行，并分隔存储。
        image_name=${image%%:*}
        image_tag=${image##*:}
        image_repo=${image%%/*}

        # 函数调用 从仓库同步镜像到本地 images 目录
        skopeo_sync" ${SOURCE_REGISTRY}/${image}" "${IMAGES_DIR}/${image_repo}"

        # 在本地 images 目录中，取得 get image manifest sha256sum 信息
        manifest="${IMAGES_DIR}/${image}/manifest.json"
        # 62ffc2ed7554e4c6d360bce40bbcf196573dd27c4ce080641a2c59867e732dee
        manifest_sha256=$(sha256sum "${manifest}" | awk '{print $1}')
        # docker/registry/v2/blobs/sha256/62/62ffc2ed7554e4c6d360bce40bbcf196573dd27c4ce080641a2c59867e732dee
        mkdir -p "${BLOBS_PATH}/${manifest_sha256:0:2}/${manifest_sha256}"
        #  该 data 文件实际上是镜像的 manifest.json 文件
        ln -f "${manifest}" "${BLOBS_PATH}/${manifest_sha256:0:2}/${manifest_sha256}/data"
        # make image repositories dir
        mkdir -p "${REPO_PATH}/${image_name}/"{_uploads,_layers,_manifests}
        mkdir -p "${REPO_PATH}/${image_name}/_manifests/revisions/sha256/${manifest_sha256}"
        mkdir -p "${REPO_PATH}/${image_name}/_manifests/tags/${image_tag}/"{current,index/sha256}
        mkdir -p "${REPO_PATH}/${image_name}/_manifests/tags/${image_tag}/index/sha256/${manifest_sha256}"
        # create image tag manifest link file
        # sha256:62ffc2ed7554e4c6d360bce40bbcf196573dd27c4ce080641a2c59867e732deer
        echo -n "sha256:${manifest_sha256}" > "${REPO_PATH}/${image_name}/_manifests/revisions/sha256/${manifest_sha256}/link"
        echo -n "sha256:${manifest_sha256}" > "${REPO_PATH}/${image_name}/_manifests/tags/${image_tag}/current/link"
        echo -n "sha256:${manifest_sha256}" > "${REPO_PATH}/${image_name}/_manifests/tags/${image_tag}/index/sha256/${manifest_sha256}/link"
        # link image layers file to registry blobs dir
        # 匹配 manifest.json 中"digest"两个不带sha256的值
        sed '/v1Compatibility/d' ${manifest} | grep -Eo "\b[a-f0-9]{64}\b" | while IFS= read -r layer ; do
            # 5cc84ad355aaa64f46ea9c7bbcc319a9d808ab15088a27209c9e70ef86e5a2aa 、 beae173ccac6ad749f76713cf4440fe3d21d1043fe616dfbe30775815d1d0f6a
            mkdir -p "${BLOBS_PATH}/${layer:0:2}/${layer}"
            # 5cc84ad355aaa64f46ea9c7bbcc319a9d808ab15088a27209c9e70ef86e5a2aa 、 beae173ccac6ad749f76713cf4440fe3d21d1043fe616dfbe30775815d1d0f6a
            mkdir -p "${REPO_PATH}/${image_name}/_layers/sha256/${layer}"
            # sha256:5cc84ad355aaa64f46ea9c7bbcc319a9d808ab15088a27209c9e70ef86e5a2aa
            echo -n "sha256:${layer}" > "${REPO_PATH}/${image_name}/_layers/sha256/${layer}/link"
            # 复制images目录中 "application/vnd.docker.container.image.v1+json" 容器配置 config 与 多个 "application/vnd.docker.image.rootfs.diff.tar.gzip" layer
            ln -f "${IMAGES_DIR}/${image}/${layer}" "${BLOBS_PATH}/${layer:0:2}/${layer}/data"
        done
    done
}

convert_images

```

运行一个 registry 来测试

```bash
docker run -itd -p 6000:5000 --name registry-tmp2 -v ${PWD}:/var/lib/registry registry:2

docker pull 192.168.31.100:6000/kubesphere/kube-apiserver:v1.20.6
```

使用脚本将 registry 存储中的镜像转换成 skopeo dir 的方式，然后再将镜像同步到 registry 中

- install-images.sh

```bash
#!/bin/bash

REGISTRY_DOMAIN="192.168.31.100:5000"
REGISTRY_PATH="/var/lib/registry"
REGISTRY_PATH="/code/srliao/mytest/skopeo/test"

# 定义 registry 存储的 blob 目录 和 repositories 目录，方便后面使用
BLOB_DIR="docker/registry/v2/blobs/sha256"
REPO_DIR="docker/registry/v2/repositories"

# 定义生成 skopeo 目录
SKOPEO_DIR="docker/skopeo"

gen_skopeo_dir() {
    # 切换到 registry 存储主目录下
    [[ -d "${SKOPEO_DIR}" ]] && rm -rf "${SKOPEO_DIR}" && mkdir -p "${SKOPEO_DIR}"
    # 通过 find 出 current 文件夹可以得到所有带 tag 的镜像，因为一个 tag 对应一个 current 目录
    while IFS= read -r -d '' image; do
        # 根据镜像的 tag 提取镜像的名字
        name=$(echo "${image}" | awk -F '/' '{print $5"/"$6":"$9}')
        link=$(sed 's/sha256://' "${image}/link")
        mfs="${BLOB_DIR}/${link:0:2}/${link}/data"
        # 创建镜像的硬链接需要的目录
        mkdir -p "${SKOPEO_DIR}/${name}"
        # 硬链接镜像的 manifests 文件到目录的 manifest 文件
        ln "${mfs}" "${SKOPEO_DIR}/${name}/manifest.json"
        # 使用正则匹配出所有的 sha256 值，然后排序去重
        layers=$(grep -Eo "\b[a-f0-9]{64}\b" "${mfs}" | sort -n | uniq)
        for layer in ${layers}; do
            # 硬链接 registry 存储目录里的镜像 layer 和 images config 到镜像的 dir 目录
            ln "${BLOB_DIR}/${layer:0:2}/${layer}/data" "${SKOPEO_DIR}/${name}/${layer}"
        done
    done < <(find ${REPO_DIR} -type d -name "current" -print0)
}

sync_image() {
    # 使用 skopeo sync 将 dir 格式的镜像同步到 regsitry 存储中
    pushd ${SKOPEO_DIR} > /dev/null || exit 1
    while IFS= read -r -d '' project; do
        skopeo sync \
            --insecure-policy --src-tls-verify=false --dest-tls-verify=false \
            --src dir --dest docker \
            "${project}" "${REGISTRY_DOMAIN}/${project}"
    done < <(find ${SKOPEO_DIR} -mindepth 1 -maxdepth 1 -type d -print0)
    popd > /dev/null || exit 1
}

pushd ${REGISTRY_PATH} > /dev/null || exit 1
gen_skopeo_dir
sync_image
popd > /dev/null || exit 1

```

从 registry 存储中 select 出镜像进行同步

先将镜像同步到一个 registry 中，再将镜像从 registry 存储中拿出来，该 registry 可以当作一个镜像存储的池子，使用 Linux 中硬链接的特性将镜像"复制" 一份出来，然后再打一个 tar 包，这样做的好处就是每次打包镜像的时候都能复用历史的镜像数据，而且性能极快

- image-select.sh

```bash
#!/bin/bash

set -eo pipefail

# 命令行变量
IMAGES_LIST="$1"
REGISTRY_PATH="$2"
OUTPUT_DIR="$3"

# Registry 仓库数据目录
BLOB_DIR="docker/registry/v2/blobs/sha256"
REPO_DIR="docker/registry/v2/repositories"

# 判断输出目录是否存在如不存在则移除。
[ -d "${OUTPUT_DIR}" ] && rm -rf "${OUTPUT_DIR}" && mkdir -p "${OUTPUT_DIR}"

find "${IMAGES_LIST}" -type f -name "*.list" -exec grep -Ev '^#|^/' {} \; | grep ':' | while IFS= read -r image; do

    # 镜像名称和Tag
    image_name=${image%%:*}
    image_tag=${image##*:}
    # link 路径获取
    tag_link="${REGISTRY_PATH}/${REPO_DIR}/${image_name}/_manifests/tags/${image_tag}/current/link"
    manifest_sha256=$(sed 's/sha256://' "${tag_link}")
    manifest="${REGISTRY_PATH}/${BLOB_DIR}/${manifest_sha256:0:2}/${manifest_sha256}/data"
    mkdir -p "${OUTPUT_DIR}/${BLOB_DIR}/${manifest_sha256:0:2}/${manifest_sha256}"
    # 强制硬链接到指定目录
    ln -f "${manifest}" "${OUTPUT_DIR}/${BLOB_DIR}/${manifest_sha256:0:2}/${manifest_sha256}/data"
    # make image repositories dir
    mkdir -p "${OUTPUT_DIR}/${REPO_DIR}/${image_name}/"{_uploads,_layers,_manifests}
    mkdir -p "${OUTPUT_DIR}/${REPO_DIR}/${image_name}/_manifests/revisions/sha256/${manifest_sha256}"
    mkdir -p "${OUTPUT_DIR}/${REPO_DIR}/${image_name}/_manifests/tags/${image_tag}/{current,index/sha256}"
    mkdir -p "${OUTPUT_DIR}/${REPO_DIR}/${image_name}/_manifests/tags/${image_tag}/index/sha256/${manifest_sha256}"
    # create image tag manifest link file
    echo -n "sha256:${manifest_sha256}" > "${OUTPUT_DIR}/${REPO_DIR}/${image_name}/_manifests/tags/${image_tag}/current/link"
    echo -n "sha256:${manifest_sha256}" > "${OUTPUT_DIR}/${REPO_DIR}/${image_name}/_manifests/revisions/sha256/${manifest_sha256}/link"
    echo -n "sha256:${manifest_sha256}" > "${OUTPUT_DIR}/${REPO_DIR}/${image_name}/_manifests/tags/${image_tag}/index/sha256/${manifest_sha256}/link"
    # 强制创建 /docker/registry/v2/blobs/ 各 layer data 文件到指定目录之中
    sed '/v1Compatibility/d' "${manifest}" | grep -Eo '\b[a-f0-9]{64}\b' | sort -u | while IFS= read -r layer; do
        mkdir -p "${OUTPUT_DIR}/${BLOB_DIR}/${layer:0:2}/${layer}"
        mkdir -p "${OUTPUT_DIR}/${REPO_DIR}/${image_name}/_layers/sha256/${layer}"
        ln -f "${BLOB_DIR}/${layer:0:2}/${layer}/data" "${OUTPUT_DIR}/${BLOB_DIR}/${layer:0:2}/${layer}/data"
        echo -n "sha256:${layer}" > "${OUTPUT_DIR}/${REPO_DIR}/${image_name}/_layers/sha256/${layer}/link"
    done

done

```
