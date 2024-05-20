控制参数

| Control Parameters     | 含义                                                         | 用法                                        |
| ---------------------- | ------------------------------------------------------------ | ------------------------------------------- |
| `max_depth`            | 树的最大深度                                                 | 当模型过拟合时,可以考虑首先降低 `max_depth` |
| `min_data_in_leaf`     | 叶子可能具有的最小记录数                                     | 默认20，过拟合时用                          |
| `feature_fraction`     | 例如 为0.8时，意味着在每次迭代中随机选择80％的参数来建树     | boosting 为 random forest 时用              |
| `bagging_fraction`     | 每次迭代时用的数据比例                                       | 用于加快训练速度和减小过拟合                |
| `early_stopping_round` | 如果一次验证数据的一个度量在最近的`early_stopping_round` 回合中没有提高，模型将停止训练 | 加速分析，减少过多迭代                      |
| lambda                 | 指定正则化                                                   | 0～1                                        |
| `min_gain_to_split`    | 描述分裂的最小 gain                                          | 控制树的有用的分裂                          |
| `max_cat_group`        | 在 group 边界上找到分割点                                    | 当类别数量很多时，找分割点很                |