## 使用 proto 生成 Python 代码

从 protobufs 生成 Python 代码。这个工作是作为 grpcio-tools 包的一部分

首先，定义初始目录结构:

```
.
├── protobufs/
│   └── recommendations.proto
|
└── recommendations/

```

protobufs 包含 recommendations.proto 文件，这是我们上面定义的部分。

将在 recommendations 目录生成 Python 代码。首先，需要安装 grpcio-tools，创建

```
grpcio-tools ~= 1.30
```

从 protobufs 生成代码

```
python -m grpc_tools.protoc -I ../protobufs --python_out=. \
         --grpc_python_out=. ../protobufs/recommendations.proto
```

此处将生成两个文件

```
> ls
recommendations_pb2.py recommendations_pb2_grpc.py
```

包含与 API 通讯的 Python 类型和函数。编译器生成客户端代码并调用 RPC 和 Server 端代码实现远程调用

## RPC 客户端

这里生成的代码可读性并不高

```python
>>> from recommendations_pb2 import BookCategory, RecommendationRequest
>>> request = RecommendationRequest(
...     user_id=1, category=BookCategory.SCIENCE_FICTION, max_results=3
... )
>>> request.category
1

```

protobuf 编译器生成了与你的 protobuf 类型对应的 Python 类型

```python
>>> request = RecommendationRequest(
...     user_id="oops", category=BookCategory.SCIENCE_FICTION, max_results=3
... )
Traceback (most recent call last):
  File "<stdin>", line 1, in <module>
TypeError: 'oops' has type str, but expected one of: int, long

```

如果传入错误字段类型，则抛出 TypeError。

在 proto3 中所有字段是可选的，所以你要校验是否正确设置所有值。如果其中一个未提供，如果为数值类型则默认为 0，如果是字符类型默认为空：

```python
>>> request = RecommendationRequest(
...     user_id=1, category=BookCategory.SCIENCE_FICTION
... )
>>> request.max_results
0

```

