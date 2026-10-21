## 可靠性概述

非易失性固态硬盘（NVMe-based SSD）以极高读写性能、极低延迟推动云环境的演进。大规模部署下，SSD 可靠性也是企业级用户的重点关注之一。

可靠性指的是一个部件或系统在规定的操作条件下，在特定的时间内继续执行其预定功能的概率。

对于企业级 SSD 而言，可靠性是非常重要的一项指标。而硬件是 SSD 产品的基础，硬件设计的质量不但会直接决定产品出货的良率、故障率等核心指标，而且对数据可用性、一致性的保护，也起着关键的作用。

## 平均故障时间 MTBF

MTBF（Mean Time between Failures，平均故障间隔时间） 是一个可靠性量化指标，单位为“小时”。它反映了产品的时间质量，产品在总的使用阶段累计工作时间与故障次数的比值为 MTBF。MTBF 通常用于一个故障可恢复的系统，是指系统两次故障间隔时间的平均值，也称为平均故障间隔。简单地说，产品故障少，也就是 MTBF 越高，意味着产品可靠性越高。

MTBF 在硬件设计之初就需要考虑，可以用来评估不同品牌、型号硬盘的可靠性。Memblaze PBlaze 系列 以 2,000,000（2 百万）小时 MTBF 为硬件可靠性目标，完成这个目标除了硬件电路的设计，重点还要考虑元器件的选型。因为 MTBF 的理论设计和每个元器件的故障率λ息息相关，还要考虑元器件如分立元器件（电容、电感、电阻）的使用数量，串联、并联的不同方式。

MTBF 也是一个需要实际跑测验证的指标，但因为完成 MTBF 不间断测试非常耗时（200 万小时相当于 228 年），因此一般 SSD 厂商都是基于一定样本量、一定时间段（通过加速因子加速）进行统计推断，模拟典型用户场景，通过实测验证理论值，代表用户提前验收产品质量。

### MTBF 在浴盆曲线的表征时期

电子产品有失效浴盆曲线的特性，通常用作视觉模型来说明产品失效率的三个关键时期。

![img](https://static001.geekbang.org/infoq/14/14e9e908b61635eb5b477b210b4414e3.png" title=")

- 早期失效（Early life failure rate or infant mortality)：这一阶段的特征是产品在开始使用时失效率很高，但随着产品工作时间的增加，失效率迅速降低。Memblaze 对所有生产线上的产品会进行一定时长的老化跑测，老化过程可以最大程度上暴露产品可能的早期失效，对正式出货产品进一步筛选

- 偶然失效期（Random Failures or Normal Life）：这一阶段的特点是产品失效率较低，且较稳定，产品可靠性指标 MTBF 所描述的就是这个时期，这一时期是产品的稳定使用阶段

- 损耗期（Wearout Phase）：该阶段的失效率随时间的延长而呈指数级增加, 主要由磨损、老化和耗损等原因造成。如 SSD 在宣称寿命结束后还是可以继续使用，但此时坏块会随着 PE 的增加而加速上升，有效预留空间（OP）降低，设备失效率提高

### MTBF = MTTF？

对于一个可维护的设备，**MTBF = MTTF + MTTR**，三者关系如下图所示：

![img](https://static001.geekbang.org/infoq/3c/3cb9f927d428704edb6417de94282fa7.png" title=")

- MTTF (Mean Time To Failure，平均失效时间)：指系统两次失效的平均时间，取所有从系统开始正常运行到发生故障之间的时间段的平均值。 MTTF =∑T1/ N

- MTTR (Mean Time To Repair，平均修复时间)：指系统从发生故障到维修结束之间时间段的平均值。MTTR =∑(T2+T3)/ N

- MTBF (Mean Time Between Failure，平均无故障时间)：指系统两次故障发生之间（包括故障维修）时间段的平均值。 MTBF =∑(T2+T3+T1)/ N

因为 MTTR 通常远远小于 MTTF，所以 MTBF 近似等于 MTTF。MTBF 用于可维护性和不可维护的系统。在传统机械硬盘（HDD）产品手册中能看到 1,000,000 或 1,500,000 小时的 MTBF 标称。

## MTTF 理论计算公式

最简单的情况下，MTTF 计算遵循如下公式。

![img](https://static001.geekbang.org/infoq/60/60e10e8592fe2a3c398e2b16ca80fd22.png" title=")

其中：

- *A*i 为 SSD i 的加速因子

- *t*i 为 SSD i 的测试时间

- *nf* 为出现故障 SSD 的数量

- a 为置信度 (confidence limit，60%)

- X2 为卡方分布 （chi-squared distribution）

上述等式中的加速因子通常分为 3 类：

- 未加速因子 ：A=1，通常用于固件故障。

- TBW（Total Bytes Written）加速因子 ：通过增加数据写入量进行寿命加速

- 温度加速因子 ：通过升高测试环境温度进行故障出现加速

##### TBW 加速因子

TBW 是 SSD 寿命单位，以寿命为 1.5 DWPD，用户容量 3.84TB PBlaze6 SSD 为例，5 年总的数据写入量（也就是现场部署写入量 field）为 10.5 PBW，对应每天数据写入量为 5.76 TBW。如果增加每天的数据写入量（加速写入量 stress），相当于加快消耗 SSD 寿命，可以加速故障出现。对于 TBW 加速因子，计算方法如下：

![img](https://static001.geekbang.org/infoq/7a/7a8bb07b34f32d139722588dbc25484b.png" title=")

假设对于一个用户容量为 100G 的 SSD，产品规格书定义 SSD 寿命为 175TBW，连续 5 年（43800 个小时）。在 1008 小时内写入 130TB 的数据，写放大为 1.2，则 TBW 加速因子为 32。

![img](https://static001.geekbang.org/infoq/b9/b9e196c76afd8fce5e016a179cdd969d.png" title=")

##### 温度加速因子

JESD 22-A108 定义了温度随时间对 SSD 的影响，执行高温运行寿命 （HTOL，High Temperature Operating Life）测试，以确定长时间在高温条件下运行的设备的可靠性，协议定义如果没有特殊要求，SSD 设备需在 125 °C 的结温（Junction Temperature）压力下测试，但企业级 SSD 会设计高温保护逻辑，防止温度过高造成 NAND 数据保持力下降和元器件的损坏，所以 SSD 的实际工作温度不会达到 125℃。

对于温度加速因子，计算方法如下：

![img](https://static001.geekbang.org/infoq/af/af8047dc20ce7c3ef2037068efe5dae3.png" title=")

其中

- Ea 为失效模型的活化能 ，一般为 0.7 eV

- k 为 玻尔兹曼常数，8.617 x 10-5 eV/°K

- T₁ 为工作温度 （标准取值为 55°C 或者 328°K）

- T₂ 为测试加速温度（单位开尔文°K）

**MTTF 计算示例（包括 TBW 和温度加速）**

假设样本量为 400，测试时间为 1008 小时，加速因子 Ai = A(TBW) * A(T) 为 10，失败的数量为 0，置信度为 60%，则

![img](https://static001.geekbang.org/infoq/13/139b59a9095587612bb6f4142ddc6a8b.png" title=")

**注意， MTBF 标称和温度有关**

NAND 因为固有特性，数据保持力会随着温度的升高会降低，由瑞典的阿伦尼乌斯所创立的阿伦尼乌斯公式（Arrhenius Equation），可以推算出，达到室温 40℃ 下 SSD 放置 1 年（8670 个小时），即相当于在 85℃ 的老化室中放置 52 个小时。因此，OCP Datacenter NVMe® SSD Specification 中提到大型互联网厂商选型 SSD 的可靠性指标要求：

- **SSD 运行环境温度在 0℃~50℃，MTBF 要求达到 2,500,000 小时（AFR≤0.35%）**

- **SSD 运行环境温度在 0℃~55℃，MTBF 要求达到 2,000,000 小时（AFR≤0.44%）**

## MTBF 和 AFR 的关系

除了 MTBF 指标，还有其他可靠性量化表征指标，如故障率λ（Failure Rate）和年化故障率 AFR（Annualized Failure Rate）。

- **故障率λ** **：** SSD 关键元器件选型时、需要确保每个元器件的故障率 λ 达标。 相比故障率指标，MTBF 的定义更加直接，也更适用于表现系统级的可靠性，更常用于预测和表征产品的可靠性。

- **AFR：**年化故障率，可以更好地了解在任何一年中发生硬盘故障的机会。

MTBF 和 AFR 都是针对大样本量的可靠性统计，二者可以相互转化，公式如下：

- MTBFhours =1/λhours，MTBFyears = 1/(λhours * 24 * 365)

- AFR = 365 * 24hours * λhours= 8760/MTBFhours, MTBF 以小时为单位（8760 是一年的小时数）

![img](https://static001.geekbang.org/infoq/31/31cae62b6a4fb44469ace0a3a516f2a8.png" title=")

根据 JEDEC JESD 218 定义，企业级 SSD 在宣称的生命周期内必须保证 FFR≤3%，UBER≤

10-16 ，关机后 SSD 在 40℃常温下必须达到 3 个月的数据保持力。其中功能故障要求 FFR（Functional Failure Requirement，The allowed cumulative functional failures over the TBW rating， 即 SSD 在整个磨损寿命时间范围内累积的功能失效率）这个指标也是 AFR 和 MTBF 的另一种表征方式（FFR = AFR * 5 年，以 5 年保修期）。

![img](https://static001.geekbang.org/infoq/c9/c9ba3b4008ad1638c6efe2c7b4f604ce.png" title=")

> For example, an FFR of 3% could be viewed as representing an annualized failure rate (AFR) of 0.6% averaged over a five-year life, or a mean time between failures (MTBF) of 5 years divided by 0.03, or about 1.5 million hours.

根据 JESD 218 的解释，FFR≤3%的要求，等价于 AFR≤0.6%，MTBF 是 1,500,000 小时。

![img](https://static001.geekbang.org/infoq/28/2847722fc4c97ffda2a8fe6871a9bc51.png" title=")

## 根据实际出货统计的失效率 CFR

SSD 产品可靠性 MTBF ≥ 200 万小时，即平均无故障运行超过 200 万小时， 换算为**年化失效率 AFR ≤ 0.44%**。AFR 是年化故障率的简称，此处的“年化”一词意味着无论观察期是月、季度等，故障率都将转换为年度评测。

在用户端，一般还会提到累积失效率 CFR（Cumulative Failure Rate）的概念。CFR 的计算需要实际统计在特定时间（可以是月、季度等）的出货量和失效数。2020 年 1 月出货量为 X1，2 月出货量为 X2，依次类推到 2021 年 3 月的出货量为 X15，在这 15 个月（10950 小时）统计中一共出现 N 次设备失效：

**CFR** = N/(X1*15*31*24+ X1*14*31*24+…+ X15*31*24) * 10950hs * 100%

## RDT 验证

RDT，也就 Reliability Demonstration Test，产品可靠性测试，是产品测试中通过大样本验证产品的平均故障时间（MTBF），是成本投入非常大的一项测试，也是接近真实使用场景，保证产品在大规模量产的时候不出现规模级别的软件和硬件异常问题。

Memblaze 凭借对企业级固态硬盘技术的深入理解，深厚的软件和固件专业知识、故障机制等知识，自研先进的 RDT 测试平台 – Whale 系统。

> Whale 有“鲸鱼”之意，早在我国先秦的典籍里，就有关于鲸的记载，叫鲲，庄周的《逍遥游》里记录“鲲之大，不知其几千里也”，所以“鲸鱼”也是“庞大”的代名词。这也是 Memblaze 为自研 MTBF 测试平台命名 Whale 的原因，因为 MTBF 要通过大样本进行跑测统计，Whale 系统可以实现 SSD 的批量测试。

RDT 测试参照的 JEDEC 标准：

- **JESD218**: Solid-State Drive (SSD) Requirements and Endurance Test Method，该标准定义了消费级和企业级 SSD 的使用条件和相应的耐久性（寿命）验证要求

- **JESD219**: Solid State Drive (SSD) Endurance Workloads. 该标准定义了 SSD 耐久性测试的工作负载。企业级 SSD 工作负载与 JESD218 定义的工作条件结合使用

- **JESD 22-A108**: Temperature, Bias, and Operating Life，定义了执行高温运行寿命 （HTOL，High Temperature Operating Life）测试，以确定长时间在高温条件下运行的设备的可靠性

RDT 跑测采用顺序、随机读写混合 IO 负载（该工作复杂通过大数据抓取分析，接近真实用户场景），并通过理论推导，得出 TBW 加速因子对应每天需要的数据写入量，每天连续掉电跑测，对一些重点项目进行严格监控。 通过实测数据来佐证 SSD 可靠性 MTBF ≥ 200 万小时，即平均无故障运行超过 200 万小时。

通过实测数据来佐证 SSD 可靠性 MTBF ≥ 200 万小时，即平均无故障运行超过 200 万小时。
