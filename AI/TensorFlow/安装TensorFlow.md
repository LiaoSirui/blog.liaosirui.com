## pip 软件包

TensorFlow `pip` 软件包对采用 CUDA 的显卡提供 GPU 支持：

```bash
pip install tensorflow
```

必须在系统中安装以下 NVIDIA软件：

- [NVIDIA GPU 驱动程序](https://www.nvidia.com/drivers) - CUDA 11.2 要求 450.80.02 或更高版本
- [CUDA 工具包](https://developer.nvidia.com/cuda-toolkit-archive)：TensorFlow 支持 CUDA 11.2（TensorFlow 2.5.0 及更高版本）
- CUDA 工具包附带的 [CUPTI](http://docs.nvidia.com/cuda/cupti/)
- [cuDNN SDK 8.1.0](https://developer.nvidia.com/cudnn) ；[cuDNN 版本](https://developer.nvidia.com/rdp/cudnn-archive)
- （可选）[TensorRT 6.0](https://docs.nvidia.com/deeplearning/tensorrt/archives/index.html#trt_6)，可缩短用某些模型进行推断的延迟时间并提高吞吐量

GPU 支持官方文档地址：<https://www.tensorflow.org/install/gpu>