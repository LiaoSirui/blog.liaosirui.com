## DSSA

DSSA（Domain Specific Software Architecture）是在一个特定应用领域中，为一组应用提供组织结构参考的标准软件架构。

它的目标是领域级复用：先为一个领域建立参考架构和可复用构件，再基于它们快速开发该领域内的多个系统。

## DSSA 领域

从功能覆盖的范围角度通常有两种理解 DSSA 中领域的含义的方式。

（1）垂直域：定义了一个特定的系统族，包含整个系统族内的多个系统，结果是在该领域中可作为系统的可行解决方案的一个通用软件体系结构。

（2）水平域：定义了在多个系统和多个系统族中功能区域的共有部分。在子系统级上涵盖多个系统族的特定部分功能。

## DSSA 的基本活动

- 领域分析
- 领域设计
- 领域实现

```mermaid
flowchart TB
    subgraph row1[" "]
        direction LR
        A["领域分析"] --- A1["定义领域边界<br/>明确分析对象<br/>识别信息源"]
        A1 ==> M(("领域模型"))
    end

    subgraph row2[" "]
        direction LR
        D["领域设计"] --- D1["描述解决方案<br/>抽象 DSSA"]
        D1 ==> DSSA(("DSSA"))
    end

    subgraph row3[" "]
        direction LR
        I["领域实现"] --- I1["提取或开发<br/>可重用信息"]
    end

    A --> D
    D --> I
    I -.->|反馈与迭代| A

    style row1 fill:transparent,stroke:transparent
    style row2 fill:transparent,stroke:transparent
    style row3 fill:transparent,stroke:transparent

    classDef phase fill:#f5f0ff,stroke:#9565e8,stroke-width:1.5px,color:#333
    classDef detail fill:#fff,stroke:#444,stroke-width:1.5px,color:#333
    classDef output fill:#fff,stroke:#444,stroke-width:1.5px,color:#333

    class A,D,I phase
    class A1,D1,I1 detail
    class M,DSSA output
```

## 参与 DSSA 的人员

参与 DSSA 的人员可以划分为 4 种角色：领域专家、领域分析师、领域设计人员和领域实现人员。
