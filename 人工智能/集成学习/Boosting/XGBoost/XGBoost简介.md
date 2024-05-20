## XGBoost 简介

XGBoost 就是一种高效、灵活且可扩展的梯度提升树（GBDT）库，广泛用于回归、分类和排序问题。XGBoost 通过引入二阶导数的优化、正则化和分布式计算，显著提升了模型的性能和计算速度

### XGBoost 原理

- 梯度提升树的基本概念

梯度提升（Gradient Boosting）是一种迭代的机器学习方法，结合了多个弱学习器（通常是决策树），逐步提升模型的性能。核心思想是每一次训练一个新的弱学习器来纠正之前模型的错误

## XGBoost 使用

```python
import xgboost as xgb

# 第一步，读取数据
xgb.DMatrix()

# 第二步，设置参数
param = {}

# 第三步，训练模型
bst = xgb.train(param)

# 第四步，预测结果
bst.predict()
```



## 参考资料

- <https://mp.weixin.qq.com/s/4WdzUu8lZscHfPzcisIAlA>