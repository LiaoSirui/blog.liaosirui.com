安装依赖

```bash
dnf install -y cmake
```

编译安装 GPU 版本（CUDA）

```bash
wget https://github.com/microsoft/LightGBM/archive/refs/tags/v4.3.0.tar.gz
mkdir LightGBM
tar zxvf v4.3.0.tar.gz -C LightGBM

cd LightGBM
mkdir build
cd build
cmake -DUSE_CUDA=1 ..
# cmake -DCMAKE_CUDA_ARCHITECTURES=native -DCMAKE_CUDA_COMPILER=/usr/local/cuda-12.4/nvcc  -DUSE_CUDA=1 ..

make -j$(nproc)

# 直接封装 whl
sh ./build-python.sh bdist_wheel --cuda --precompile

pip3 install numpy==1.20
```

GPU 测试用 demo

```python
import lightgbm as lgb
import numpy as np
# from sklearn.datasets import make_regression
 
# X, y = make_regression(n_samples=10_000000)
X = np.random.rand(500000, 200)  # 500个样本，10个特征
y = np.random.randint(2, size=500000)  # 二分类标签
dtrain = lgb.Dataset(X, label=y)
bst = lgb.train(
    params={
        "objective": "regression",
        "device": "cuda",
        "verbose": 1
    },
    train_set=dtrain,
    num_boost_round=100
)
```

