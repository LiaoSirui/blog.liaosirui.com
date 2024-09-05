## Tushare 简介

Tushare 是一个为金融行业研究人员、数据分析师、算法交易者提供历史市场数据、实时行情、交易数据、参考数据、社会网络数据、新闻及研报等的金融数据接口库。它为我们提供了一个简单方便的方式来获取和分析金融数据

Tushare 的数据不是直接从互联网抓取，而是通过社区的采集和整理存入数据库经过质量控制后再提供给用户，数据的质量和稳定性更有保障

官方：

- 官网：<https://tushare.pro/>

## Tushare 安装和使用

Tushare 的安装命令如下：

```
pip install tushare
```

查看当前版本的方法：

```python
import tushare
print(tushare.__version__)
```

调用 Tushare 的数据需要有相应积分；访问 Tushare 的官方网站，注册成功后，可以在个人中心找到 API 密钥

在 Python 中配置 Tushare

```python
import tushare as ts

ts.set_token('your token')
```

数据字典：<https://tushare.pro/document/2>

### 获取 A 股基础数据

Tushare 提供以下基础数据：股票基础信息、交易日历、股票曾用名、沪深股通成份股、上市公司基本信息、上市公司管理层、管理层薪酬和持股、IPO 新股列表等

可以使用 Tushare 的 stock_basic 接口来获取 A 股的基础信息。此接口提供了包括股票代码、名称、上市日期、退市日期等基础信息的数据

```python
pro = ts.pro_api()

# 查询当前所有正常上市交易的股票列表
data = pro.stock_basic(exchange='', list_status='L', fields='ts_code,symbol,name,area,industry,list_date')
```

### 获取股票行情数据

Tushare 提供以下股票行情数据：日线行情、周线行情、月线行情、复权行情、复权因子、每日停复牌信息、每日指标、个股资金流向、每日涨跌停价格、沪深港通资金流向、沪深股通十大成交股、港股通十大成交股、港股通每日成交统计、港股通每月成交统计等

可以使用 Tushare 的 daily 接口来获取 A 股的日线行情数据。此接口可以提供每个交易日的数据，数据在每个交易日的 15 点到 16 点之间更新。需要注意的是，这个接口提供的是未复权行情，停牌期间不会提供数据

```python
pro = ts.pro_api()

# 查询单个股票的日线行情
df = pro.daily(ts_code='000001.SZ', start_date='20180701', end_date='20180718')

# 查询多个股票的日线行情
df = pro.daily(ts_code='000001.SZ,600000.SH', start_date='20180701', end_date='20180718')

# 查询某一天全部股票的日线行情
df = pro.daily(trade_date='20180810')
```

###  获取财务数据

Tushare 提供以下财务数据：利润表、资产负债表、现金流量表、业绩预告、业绩快报、分红送股、财务指标数据、财务审计意见、主营业务构成、财报披露计划等

使用 Tushare 的 forecast 接口来获取 A 股的业绩预告数据。当前这个接口主要用于按单只股票获取其历史业绩预告数据

```python
pro = ts.pro_api()

# 查询当前所有正常上市交易的股票列表
data = pro.stock_basic(exchange='', list_status='L', fields='ts_code,symbol,name,area,industry,list_date')
```

### 获取股票行情数据

Tushare 提供以下股票行情数据：日线行情、周线行情、月线行情、复权行情、复权因子、每日停复牌信息、每日指标、个股资金流向、每日涨跌停价格、沪深港通资金流向、沪深股通十大成交股、港股通十大成交股、港股通每日成交统计、港股通每月成交统计等

可以使用 Tushare 的 daily 接口来获取 A 股的日线行情数据。此接口可以提供每个交易日的数据，数据在每个交易日的 15 点到 16 点之间更新。需要注意的是，这个接口提供的是未复权行情，停牌期间不会提供数据

```python
pro = ts.pro_api()

# 查询单个股票的日线行情
df = pro.daily(ts_code='000001.SZ', start_date='20180701', end_date='20180718')

# 查询多个股票的日线行情
df = pro.daily(ts_code='000001.SZ,600000.SH', start_date='20180701', end_date='20180718')

# 查询某一天全部股票的日线行情
df = pro.daily(trade_date='20180810')
```

###  获取财务数据

Tushare 提供以下财务数据：利润表、资产负债表、现金流量表、业绩预告、业绩快报、分红送股、财务指标数据、财务审计意见、主营业务构成、财报披露计划等

使用 Tushare 的 forecast 接口来获取 A 股的业绩预告数据。当前这个接口主要用于按单只股票获取其历史业绩预告数据

```python
pro = ts.pro_api()

# 获取单个股票的业绩预告数据
df = pro.forecast(ann_date='20190131', fields='ts_code,ann_date,end_date,type,p_change_min,p_change_max,net_profit_min')

# 获取某一季度全部股票的业绩预告数据
df = pro.forecast_vip(period='20181231',fields='ts_code,ann_date,end_date,type,p_change_min,p_change_max,net_profit_min')
```

### 获取市场参考数据

Tushare 提供的市场参考数据包括：融资融券交易汇总、融资融券交易明细、融资融券标的、前十大股东、前十大流通股东、龙虎榜每日明细、龙虎榜机构明细、股权质押统计数据、股权质押明细、股票回购、限售股解禁、大宗交易、股东人数、股东增减持等

使用 Tushare 的 top_list 接口来获取 A 股的龙虎榜每日交易明细：

```python
pro = ts.pro_api()

# 获取某一交易日的龙虎榜交易明细
df = pro.top_list(trade_date='20180928')
```

### 获取特色数据

Tushare 还提供了很多特色数据：卖方盈利预测数据、每日筹码及胜率、每日筹码分布、股票技术因子、中央结算系统持股汇总、中央结算系统持股明细、沪深港股通持股明细、每日涨跌停和炸板数据、机构调研数据、券商每月金股、游资名录、游资每日明细等

可以使用 Tushare 的 cyq_chips 接口来获取 A 股的每日筹码分布情况。这个接口能够提供每个价格点的占比，数据从 2010 年开始，每天在 17 到 18 点之间更新当日数据。注意，这个接口有每次的提取限量，但可以通过循环股票代码和日期来提取更多数据

```python
pro = ts.pro_api()

# 获取某一股票在某一时间段内的筹码分布情况
df = pro.cyq_chips(ts_code='600000.SH', start_date='20220101', end_date='20220429')
```

