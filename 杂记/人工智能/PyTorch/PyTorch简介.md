## 问题处理

检查 cuda

```bash
import torch

# 检查 cuda 是否可用
torch.cuda.is_available()

# 查看 cuda 版本
torch.version.cuda
```

检查 cudnn

```bash
# 检查 cudnn 是否可用
torch.backends.cudnn.is_available()

# 查看 cudnn 版本
torch.backends.cudnn.version()

```



cuda 配置：

```bash
PYTORCH_CUDA_ALLOC_CONF=garbage_collection_threshold:0.6,max_split_size_mb:64
```

回收显存

```python
torch.cuda.empty_cache()
```

## 参考资料

- 教程：https://geek-docs.com/pytorch/pytorch-tutorial/pytorch-tutorial.html
