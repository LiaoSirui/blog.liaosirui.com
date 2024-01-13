## 问题处理

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
