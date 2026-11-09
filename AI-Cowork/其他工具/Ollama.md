## 部署模型

| 变量                       | 值       | 作用                                                         |
| -------------------------- | -------- | ------------------------------------------------------------ |
| `OLLAMA_KEEP_ALIVE`        | `-1`     | 模型一直留在显存里，不会因为空闲被卸载（原来是 24h）         |
| `OLLAMA_FLASH_ATTENTION`   | `1`      | 开启 Flash Attention，长上下文下更省显存、速度更快           |
| `OLLAMA_KV_CACHE_TYPE`     | `q8_0`   | KV cache 占用减半，精度损失很小，要配合 Flash Attention 使用 |
| `OLLAMA_NUM_PARALLEL`      | `2`      | 最多同时处理 2 个请求，每个请求都按完整的 `num_ctx` 分配 KV cache |
| `OLLAMA_MAX_LOADED_MODELS` | `1`      | 单卡只加载一个模型                                           |
| `OLLAMA_LOAD_TIMEOUT`      | `15m`    | 模型权重从 NFS 读，可能超过默认的 5 分钟加载超时             |
| `OLLAMA_CONTEXT_LENGTH`    | `262144` | 把上下文固定为模型上限 256K，不再交给 Ollama 按显存大小自动决定 |

```yaml
extraEnv:
  # Keep the model resident in VRAM forever.
  - name: OLLAMA_KEEP_ALIVE
    value: "-1"
  - name: OLLAMA_FLASH_ATTENTION
    value: "1"
  # Halve KV cache memory with negligible quality loss (requires flash attention).
  - name: OLLAMA_KV_CACHE_TYPE
    value: q8_0
  # Each parallel slot allocates a full num_ctx KV cache.
  - name: OLLAMA_NUM_PARALLEL
    value: "2"
  # Single GPU serves a single model.
  - name: OLLAMA_MAX_LOADED_MODELS
    value: "1"
  # Loading weights from NFS can exceed the default 5m.
  - name: OLLAMA_LOAD_TIMEOUT
    value: 15m
```

- `OLLAMA_SCHED_SPREAD` 模型拆分到多卡

## 显存估算

`qwen3.8:27b` 是混合注意力架构：64 层里只有 16 层是全注意力层，外加 1 层 MTP 层，其余都是线性注意力层。只有全注意力层会占用和上下文长度成正比的 KV cache，所以 KV cache 比同尺寸的普通模型小很多。

| 项目                              | 估算                                                         |
| --------------------------------- | ------------------------------------------------------------ |
| 模型权重（Q4_K_M 量化）加视觉模块 | 约 17.7GB                                                    |
| 每路并发的 KV cache（256K，q8_0） | 约 10GB（17 层 × 4 个 KV head × 256 维 × 2 × 262144 个 token） |
| 每路并发的线性注意力状态          | 约 0.15GB，可以忽略                                          |
| 4 路并发合计（加计算缓冲区）      | 约 65GB / 96GB                                               |

- 想要更高并发，可以设 `OLLAMA_NUM_PARALLEL=6`，预计约 80GB。前提是部署后先确认 4 路时实际显存占用和估算接近。
- 如果大部分请求用不到 256K，把上下文降到 128K，并发就能翻倍到 8 左右。
- 显存有富余时，可以把 `OLLAMA_KV_CACHE_TYPE` 改回 f16，换取更好的长上下文精度。这样每路并发约 20GB，只能开 3 路。