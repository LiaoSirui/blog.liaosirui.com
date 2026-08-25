文件 layout

```plain
<root>/docker/registry/v2/
├── blobs/sha256/<hex[0:2]>/<hex>/data          ← blob 内容本体（唯一副本）
└── repositories/<name>/
    ├── _layers/sha256/<hex>/link               ← 该 repo 引用的 blob（config + 各 layer）
    ├── _manifests/
    │   ├── revisions/sha256/<hex>/link         ← 该 repo 的所有 manifest（含 index 的子 manifest）
    │   └── tags/<tag>/
    │       ├── current/link                    ← tag 当前指向的 manifest digest
    │       └── index/sha256/<hex>/link         ← 该 tag 历史指向过的 manifest
    └── _uploads/                               ← 临时上传目录，可不建

```

