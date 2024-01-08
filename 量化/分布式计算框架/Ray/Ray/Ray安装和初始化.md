安装

```bash
pip install -U "ray[data,train,tune,serve]"
```

文档：<https://docs.ray.io/en/latest/ray-overview/installation.html>

先启动 head 节点

```bash
ray start --head --dashboard-host 0.0.0.0 --num-cpus 8 --num-gpus 1
```

添加节点

```bash
ray start --address='10.244.244.11:6379' --num-cpus 8 --num-gpus 1
```

参考文档：<https://docs.ray.io/en/latest/cluster/vms/references/ray-cluster-configuration.html>

查看 ray 集群状态

```bash
ray status
```

测试示例

```bash
import ray

ray.init(address="auto")  # 自动连接到已启动的集群

@ray.remote
def example_task():
    return "Hello from Ray!"

result = ray.get(example_task.remote())
print(result)

```

运行任务

```python3
import ray

# Connect to the Ray cluster
ray.init(address="auto")

@ray.remote(num_gpus=1)
def train():
    import lightgbm as lgb
    import numpy as np
    # from sklearn.datasets import make_regression

    # X, y = make_regression(n_samples=10_000000)
    X = np.random.rand(5000000, 200) # 500个样本，10个特征
    y = np.random.randint(2, size=5000000) # 二分类标签
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

result = [train.remote() for _ in range(2)]
ray.get(result)

# Close the Ray cluster
ray.shutdown()

```

多机多卡任务

```python
from typing import Tuple

import ray
from ray.data import Dataset, Preprocessor
from ray.data.preprocessors import Categorizer, StandardScaler
from ray.train.lightgbm import LightGBMTrainer
from ray.train import Result, ScalingConfig

# Connect to the Ray cluster
ray.init(address="auto")

def prepare_data() -> Tuple[Dataset, Dataset, Dataset]:
    dataset = ray.data.read_csv("s3://anonymous@air-example-data/breast_cancer_with_categorical.csv")
    train_dataset, valid_dataset = dataset.train_test_split(test_size=0.3)
    test_dataset = valid_dataset.drop_columns(cols=["target"])
    return train_dataset, valid_dataset, test_dataset

def train_lightgbm(num_workers: int, use_gpu: bool = False) -> Result:
    train_dataset, valid_dataset, _ = prepare_data()

    # Scale some random columns, and categorify the categorical_column,
    # allowing LightGBM to use its built-in categorical feature support
    scaler = StandardScaler(columns=["mean radius", "mean texture"])
    categorizer = Categorizer(["categorical_column"])

    train_dataset = categorizer.fit_transform(scaler.fit_transform(train_dataset))
    valid_dataset = categorizer.transform(scaler.transform(valid_dataset))

    # LightGBM specific params
    params = {
        "objective": "binary",
        "metric": ["binary_logloss", "binary_error"],
    }

    trainer = LightGBMTrainer(
        scaling_config=ScalingConfig(num_workers=num_workers, use_gpu=use_gpu),
        label_column="target",
        params=params,
        datasets={"train": train_dataset, "valid": valid_dataset},
        num_boost_round=100,
        metadata = {"scaler_pkl": scaler.serialize(), "categorizer_pkl": categorizer.serialize()}
    )
    result = trainer.fit()
    print(result.metrics)

    return result

result = train_lightgbm(num_workers=2, use_gpu=True)
```

