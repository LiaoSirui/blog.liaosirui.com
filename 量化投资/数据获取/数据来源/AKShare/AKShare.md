## AKShare 简介

AKShare 是一个基于 Python 的开源金融数据接口库，旨在使个人投资者和研究人员能够方便地获取广泛的金融数据

AKShare 提供的数据类型包括股票、期货、期权、基金、债券、指数、数字货币、外汇、宏观、衍生品、等各种金融数据。AKShare 开源财经数据接口库所采集的数据皆来自公开的数据源

AKShare 有以下特点：

- 广泛的数据覆盖：AKShare 提供了 A 股、港股、美股、期货、期权、外汇、基金、债券、数字货币等多种数据的获取方式。

- 易于使用：AKShare 的接口设计简洁明了，用户只需要简单的函数调用就可以获取所需的数据

官方：

- 文档：<https://akshare.akfamily.xyz/>
- GitHub 仓库：<https://github.com/akfamily/akshare>

## 安装和使用

通过 pip 进行安装


```bash
pip install akshare --upgrade
```

导入库

```python
import akshare as ak
```

数据字典：

- <https://akshare.akfamily.xyz/data/index.html#>
- <https://github.com/akfamily/akshare/blob/main/docs/data/index.rst>

### 获取行情数据

- 股票历史行情数据

使用 Akshare 的 stock_zh_a_hist 接口可以从东方财富网站获取指定 A 股上市公司的历史行情数据。这些数据包括日频率、周频率、月频率的数据，以及不同复权方式的数据

接口返回单次指定的沪深京 A 股上市公司、指定周期和指定日期间的历史行情日频率数据。历史数据按日频率更新。请注意，当日收盘价需要在收盘后获取

文档 - 历史行情数据：<https://akshare.akfamily.xyz/data/stock/stock.html#id22>

使用示例：

1）获取不复权的历史行情数据

```python
stock_zh_a_hist_df = ak.stock_zh_a_hist(
    symbol="000001",
    period="daily",
    start_date="20170301",
    end_date="20210907",
    adjust="",
)
```

2）获取前复权的历史行情数据

```python
stock_zh_a_hist_df = ak.stock_zh_a_hist(
    symbol="000001",
    period="daily",
    start_date="20170301",
    end_date="20210907",
    adjust="qfq",
)
```

3）获取后复权的历史行情数据

```python
stock_zh_a_hist_df = ak.stock_zh_a_hist(
    symbol="000001",
    period="daily",
    start_date="20170301",
    end_date="20210907",
    adjust="hfq",
)
```

- 股票实时行情数据

使用 akshare 的以下两个接口可以从东方财富网站获取实时的五档买卖数据和行情数据：

接口：stock_bid_ask_em

文档 - 行情报价：<https://akshare.akfamily.xyz/data/stock/stock.html#id9>

这个接口提供了股票的实时买卖报价信息

```python
stock_bid_ask_em_df = ak.stock_bid_ask_em(symbol="000001")
```

接口：stock_zh_a_spot_em

文档 - 实时行情数据：<https://akshare.akfamily.xyz/data/stock/stock.html#id11>

这个接口提供了所有 A 股上市公司的实时行情数据。包括了股票代码，名称，最新价，涨跌幅，涨跌额，成交量，成交额，振幅，市盈率等多个字段

```python
stock_zh_a_spot_em_df = ak.stock_zh_a_spot_em()
```

- 指数历史行情数据

akshare 库提供了一个名为 stock_zh_index_daily 的接口，可以用于获取股票指数的历史行情数据。这些数据是从新浪财经获取的，历史数据按日频率更新

使用这个接口，可以获取到一个股票指数的所有历史行情数据

文档：<https://akshare.akfamily.xyz/data/index/index.html#id3>

```python
stock_zh_index_daily_df = ak.stock_zh_index_daily(symbol="sz399552")
```

- 指数实时行情数据

akshare 库的 stock_zh_index_spot_em 接口可以获取新浪财经网站上的实时指数行情数据

文档：<https://akshare.akfamily.xyz/data/index/index.html#id1>

```python
stock_zh_index_spot_df = ak.stock_zh_index_spot_em()
```

### 基本面数据

- 财务报告

在 AKShare 库中，stock_financial_report_sina 接口提供了从新浪财经获取特定股票的财务报告数据的功能。此接口覆盖了三大财务报表：资产负债表，利润表和现金流量表。

此接口能够在单次调用中获取指定报表的所有年份数据的历史数据。接口的输入参数包括 stock 和 symbol。stock 为带有市场标识的股票代码，例如 "sh600600"。而 symbol 则是您想要查询的财务报告类型，可以选择 "资产负债表"，"利润表" 或 "现金流量表"。

该接口的输出是一个包含了多种财务数据的数据框，其中包括报告日期、流动资产等各种财务指标

- 基本面关键指标

使用 AKShare 库的 stock_financial_abstract 函数，可以轻松获取特定股票代码的财务关键指标。

这个接口的主要功能是获取新浪财经网站上的财务报表中的关键指标。每次调用，可以获取一个股票代码对应的所有历史关键指标数据

- 盈利预测数据

AKShare 库中的盈利预测接口是 stock_profit_forecast_ths，此接口源自同花顺，专门用于盈利预测。这个接口能够返回特定股票代码（symbol）和指标（indicator）的数据

### 获取特色数据

- 主力控盘：机构参与度

在 AKShare 库中，stock_comment_detail_zlkp_jgcyd_em 接口允许用户从东方财富网获取特定股票的机构参与度数据。

此接口在单次调用中可获取所有相关数据，输入参数仅需要指定 symbol，也就是股票代码。

返回的数据包含了日期（date）和机构参与度（value）。注意，value 字段的单位是百分比，代表机构投资者持股的比例

- 资金流向

在 AKShare 中可以用 stock_individual_fund_flow 接口从东方财富网获取个股资金流向的数据。该接口单次可以获取指定市场和股票的近 100 个交易日的资金流数据