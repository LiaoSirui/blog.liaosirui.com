## TPC-C

https://www.tpc.org/tpcc/

TPC 是一系列事务处理和数据库基准测试的规范。其中TPC-C（Transaction Processing Performance Council）是针对 OLTP 的基准测试模型。

TPC-C 测试模型给基准测试提供了一种统一的测试标准，可以大体观察出数据库服务稳定性、性能以及系统性能等一系列问题。对数据库展开 TPC-C 基准性能测试，一方面可以衡量数据库的性能，另一方面可以衡量采用不同硬件软件系统的性价比，也是被业内广泛应用并关注的一种测试模型。

## 测试场景

TPC-C测试用到的模型是一个大型的商品批发销售公司，它拥有若干个分布在不同区域的商品仓库。当业务扩展的时候，公司将添加新的仓库。每个仓库负责为10个销售点供货，其中每个销售点为3000个客户提供服务，每个客户提交的订单中，平均每个订单有10项产品，所有订单中约1%的产品在其直接所属的仓库中没有存货，必须由其他区域的仓库来供货。同时，每个仓库都要维护公司销售的100000种商品的库存记录

TPC-C 是一个对 OLTP（联机交易处理）系统进行测试的规范，使用一个商品销售模型对 OLTP 系统进行测试，其中包含五类事务：

* NewOrder – 新订单的生成
* Payment – 订单付款
* OrderStatus – 最近订单查询
* Delivery – 配送
* StockLevel – 库存缺货状态分析

在测试开始前，TPC-C Benchmark 规定了数据库的初始状态，也就是数据库中数据生成的规则，其中 ITEM 表中固定包含 10 万种商品，仓库的数量可进行调整，假设 WAREHOUSE 表中有 W 条记录，那么：

* STOCK 表中应有 W * 10 万条记录（每个仓库对应 10 万种商品的库存数据）
* DISTRICT 表中应有 W * 10 条记录（每个仓库为 10 个地区提供服务）
* CUSTOMER 表中应有 W * 10 * 3000 条记录（每个地区有 3000 个客户）
* HISTORY 表中应有 W * 10 * 3000 条记录（每个客户一条交易历史）
* ORDER 表中应有 W * 10 * 3000 条记录（每个地区 3000 个订单），并且最后生成的 900 个订单被添加到 NEW-ORDER 表中，每个订单随机生成 5 ~ 15 条 ORDER-LINE 记录。

TPC-C 使用 tpmC 值（Transactions per Minute）来衡量系统最大有效吞吐量（MQTh，Max Qualified Throughput），其中 Transactions 以 NewOrder Transaction 为准，即最终衡量单位为每分钟处理的新订单数。

## 部署 MySQL

建议Pod资源配置：

CPU： 2GHz （2000m）

建议配置

```
[mysqld]
innodb_buffer_pool_size=2G  # 缓存池大小 50%的内存
pxc_strict_mode=DISABLED  # 取消主键限制
max_connections=1000   # 最大连接数
lower_case_table_names = 1  # 取消表字段大小写敏感
```

### **启动测试工具容器**