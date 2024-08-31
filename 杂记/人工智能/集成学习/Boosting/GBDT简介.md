## GBDT

GBDT 是机器学习中的一个非常流行并且有效的算法模型

- XGBoost（eXtreme Gradient Boosting）：2014 年陈天奇博士提出的， 特点是计算速度快，模型表现好，可以用于分类和回归问题中
- LightGBM（Light Gradient Boosting Machine）：2017 年 1 月，由微软开源的一个机器学习框架，它的训练速度和效率更快、使用的内存更低、准确率更高、并且支持并行化学习与处理大规模数据
- CatBoost（ Categorical Features+Gradient Boosting）：2017 年 4 月，俄罗斯的搜索巨头 Yandex 开源的框架，采用的策略在降低过拟合的同时保证所有数据集都可用于学习。性能卓越、鲁棒性与通用性更好、易于使用而且更实用。据其介绍 CatBoost 的性能可以匹敌任何先进的机器学习算法
- NGBoost：2019 年 10 月，Stanford 吴恩达团队提出。暂时在早期，目前还在主要使用前三个

XGBoost、LightGBM 和 CatBoost 都是目前经典的 SOTA（state of the art）Boosting 算法，都可以归类到梯度提升决策树算法系列。三个模型都是以决策树为支撑的集成学习框架，其中 XGBoost 是对原始版本的 GBDT 算法的改进，而 LightGBM 和 CatBoost 则是在 XGBoost 基础上做了进一步的优化，在精度和速度上都有各自的优点

大的方面的区别：

- 第一个是三个模型树的构造方式有所不同，XGBoost 使用按层生长（level-wise）的决策树构建策略，LightGBM 则是使用按叶子生长（leaf-wise）的构建策略，而 CatBoost 使用了对称树结构，其决策树都是完全二叉树
- 第二个有较大区别的方面是对于类别特征的处理。XGBoost 本身不具备自动处理类别特征的能力，对于数据中的类别特征，需要我们手动处理变换成数值后才能输入到模型中；LightGBM 中则需要指定类别特征名称，算法即可对其自动进行处理；CatBoost 以处理类别特征而闻名，通过目标变量统计等特征编码方式也能实现类别特征的高效处理

## 参考资料

- <https://zhuanlan.zhihu.com/p/504646498#:~:text=4.1%20CatBoost%E7%AE%80%E4%BB%8B&text=CatBoost%E5%92%8CXGBoost%E3%80%81LightGBM%E5%B9%B6,%E7%9A%84%E4%B8%80%E7%A7%8D%E6%94%B9%E8%BF%9B%E5%AE%9E%E7%8E%B0%E3%80%82>