## 创建应用

开发 exporter 需要使用 prometheus_client 库

```bash
pip3 install prometheus_client -i https://pypi.tuna.tsinghua.edu.cn/simple/
```

具体规范可参考：<https://github.com/prometheus/client_python>，根据规范可知要想开发一个 exporter 需要：

1. 定义数据类型，metric，describe（描述），标签 
2. 获取数据 
3. 传入数据和标签 
4. 暴露端口，不断的传入数据和标签
