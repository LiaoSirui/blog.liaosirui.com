## Pip 安装

安装指定版本的：

```bash
curl https://bootstrap.pypa.io/pip/2.7/get-pip.py -o get-pip.py

python get-pip.py
```

安装最新版本的：

```bash
curl https://bootstrap.pypa.io/get-pip.py --output get-pip.py
```

## pip 离线装包

下载依赖

```
pip3 download -d ./ -r requirements.txt
```

离线安装 whl

```bash
pip3 install --no-index --find-links=DIR -r requirements.txt
```

