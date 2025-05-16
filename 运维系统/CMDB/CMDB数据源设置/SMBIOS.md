## SMBIOS

SMBIOS（ System Management BIOS）是主板或者系统制造商以标准格式显示产品信息所遵循的规范。依据该规范，BIOS 在 POST 阶段可以知道如何去创建。OS 阶段，操作系统和应用程序知道如何使用，解释内存区域表示什么意思

在物理上，SMBIOS 是上电开机，BIOS 在内存中建立的一块区域，保存了平台的相关信息。在 EFI 系统中，SMBIOS 表的地址可以通过 SMBIOS GUID （SMBIOS_TABLE_GUID）在 EFI 配置表（EFI Configuration Table）中找到

SMBIOS 表中 SMBIOS 记录的总数可以从其起始数据结构 （SMBIOS Entry Point Structure）中获得。应用程序可以从 SMBIOS Entry Point Structure 中获得所有 SMBIOS 记录的起始地址，并且通过遍历每一个 SMBIOS 记录来获得各种系统信息

## DMI

dmidecode 是一个读取电脑 DMI（桌面管理接口 Desktop Management Interface）表内容并且以人类可读的格式显示系统硬件信息的工具

## UUID

在计算机硬件管理中，System Management BIOS (SMBIOS) 是一种标准，用于描述和识别计算机硬件。 其中，每个设备都会被分配一个唯一的 Universally Unique Identifier (UUID)，用于标识这个设备

## 数据结构信息

SMBIOS EPS 表结构如下：

| 位置   | 名称            | 长度  | 描述                                               |
| ------ | --------------- | ----- | -------------------------------------------------- |
| 00H    | 关键字          | 4BYTE | 固定是 "SM"                                        |
| 04H    | 校验和          | 1BYTE | 用于校验数据                                       |
| 05H    | 表结构长度      | 1BYTE | Entry Point Structure 表的长度                     |
| 06H    | Major 版本号    | 1BYTE | 用于判断 SMBIOS 版本                               |
| 07H    | Minor 版本号    | 1BYTE | 用于判断 SMBIOS 版本                               |
| 08H    | 表结构大小      | 2BYTE | 用于即插即用接口方法获得数据表结构长度             |
| 0AH    | EPS 修正        | 1BYTE | -                                                  |
| 0B-0FH | 格式区域        | 5BYTE | 存放解释 EPS 修正的信息                            |
| 10H    | 关键字          | 5BYTE | 固定为 "DMI"                                       |
| 15H    | 校验和          | 1BYTE | Intermediate Entry Point Structure (IEPS) 的校验和 |
| 16H    | 结构表长度      | 2BYTE | SMBIOS 结构表的长度                                |
| 18H    | 结构表地址      | 4BYTE | SMBIOS 结构表的真实内存位置                        |
| 1CH    | 结构表个数      | 2BYTE | SMBIOS 结构表数目                                  |
| 1EH    | SMBIOS BCD 修正 | 1BYTE | -                                                  |

通过 EPS 表结构中 16H 以及 18H 处，得出数据表长度和数据表地址，即可通过地址访问 SMBIOS 数据结构表。从 EPS 表中的 1CH 处可得知数据表结构的总数，其中 TYPE 0 结构就是 BIOS information ， TYPE 1 结构就是 SYSTEM Information 。

每个结构的头部是相同的，格式如下：

| 位置 | 名称    | 长度  | 描述                                 |
| ---- | ------- | ----- | ------------------------------------ |
| 00H  | TYPE 号 | 1BYTE | 结构的 TYPE 号                       |
| 01H  | 长度    | 1BYTE | 本结构的长度，就此 TYPE 号的结构而言 |
| 02H  | 句柄    | 2BYTE | 用于获得本 SMBIOS 结构，其值不定     |

每个结构都分为格式区域和字符串区域，格式区域就是一些本结构的信息，字符串区域是紧随在格式区域后的一个区域。结构 01H 处标识的结构长度仅是格式区域的长度，字符串区域的长度是不固定的。有的结构有字符串区域，有的则没有。

下面以 TYPE 0 （ BIOS information ）为例说明格式区域和字符串区域的关系。 TYPE 0 （ BIOS information ）格式区域如下：

| 位置 | 名称            | 长度  | 描述                                                         |
| ---- | --------------- | ----- | ------------------------------------------------------------ |
| 00H  | TYPE 号         | 1BYTE | 结构的 TYPE 号，此处是0                                      |
| 01H  | 长度            | 1BYTE | TYPE 0 格式区域的长度，一般为14H ，也有 13H                  |
| 02H  | 句柄            | 2BYTE | 本结构的句柄，一般为0000H                                    |
| 04H  | BIOS 厂商信息   | 1BYTE | 此处是 BIOS 卖方的信息，可能是 OEM 厂商名，一般为 01H ，代表紧随格式区域后的字符串区域的第一个字符串 |
| 05H  | BIOS 版本       | 1BYTE | BIOS 版本号，一般为 02H ，代表字符串区域的第二个字符串       |
| 06H  | BIOS 开始地址段 | 2BYTE | 用于计算常驻BIOS 镜像大小的计算，方法为（10000H-BIOS 开始地址段）×16 |
| 08H  | BIOS 发布日期   | 1BYTE | 一般为03H ，表示字符区第三个字符串                           |
| 09H  | BIOS rom size   | 1BYTE | 计算方法为（n ＋1 ）×64K ，n 为此处读出数值                  |
| 0AH  | BIOS 特征       | 8BYTE | BIOS 的功能支持特征，如 PCI,PCMCIA,FLASH 等                  |
| 12H  | BIOS 特征扩展   | 不定  | -                                                            |

## 设备类型

The SMBIOS specification defines the following DMI types:

| Type | Information                      |
| ---- | -------------------------------- |
| 0    |                                  |
| 1    | System                           |
| 2    | Base Board                       |
| 3    | Chassis                          |
| 4    | Processor                        |
| 5    | Memory Controller                |
| 6    | Memory Module                    |
| 7    | Cache                            |
| 8    | Port Connector                   |
| 9    | System Slots                     |
| 10   | On Board Devices                 |
| 11   | OEM Strings                      |
| 12   | System Configuration Options     |
| 13   | BIOS Language                    |
| 14   | Group Associations               |
| 15   | System Event Log                 |
| 16   | Physical Memory Array            |
| 17   | Memory Device                    |
| 18   | 32-bit Memory Error              |
| 19   | Memory Array Mapped Address      |
| 20   | Memory Device Mapped Address     |
| 21   | Built-in Pointing Device         |
| 22   | Portable Battery                 |
| 23   | System Reset                     |
| 24   | Hardware Security                |
| 25   | System Power Controls            |
| 26   | Voltage Probe                    |
| 27   | Cooling Device                   |
| 28   | Temperature Probe                |
| 29   | Electrical Current Probe         |
| 30   | Out-of-band Remote Access        |
| 31   | Boot Integrity Services          |
| 32   | System Boot                      |
| 33   | 64-bit Memory Error              |
| 34   | Management Device                |
| 35   | Management Device Component      |
| 36   | Management Device Threshold Data |
| 37   | Memory Channel                   |
| 38   | IPMI Device                      |
| 39   | Power Supply                     |
| 40   | Additional Information           |
| 41   | Onboard Device                   |

## go-smbios

项目地址：

- <https://github.com/siderolabs/go-smbios>

可提供的信息

### （1）SMBIOS Version

<https://github.com/siderolabs/go-smbios/blob/v0.3.3/smbios/smbios.go#L18-L22>

SMBIOS 的版本，例如 3.2.0

```go
smbios.Version {
    Major: 3,
    Minor: 2,
    Revision: 0,
}

smbios.Version {
    Major: 3,
    Minor: 5,
    Revision: 0,
}
```

### （2）BIOSInformation

<https://github.com/siderolabs/go-smbios/blob/v0.3.3/smbios/bios_information.go#L10-L17>

BIOS information

- Vendor
- Version
- ReleaseDate

```go
smbios.BIOSInformation {
    Vendor: "American Megatrends Inc.",
    Version: "2.7",
    ReleaseDate: "09/21/2023",
}

smbios.BIOSInformation {
    Vendor: "American Megatrends Inc.",
    Version: "0403",
    ReleaseDate: "02/06/2023",
}
```

### （3）SystemInformation

<https://github.com/siderolabs/go-smbios/blob/v0.3.3/smbios/system_information.go#L20C6-L38>

SMBIOS system information

- Manufacturer
- ProductName
- Version
- SerialNumber
- UUID
- WakeUpType
- SKUNumber
- Family

```go
smbios.SystemInformation {
    Manufacturer: "Supermicro",
    ProductName: "AS -4124GS-TNR",
    Version: "0123456789",
    SerialNumber: "A404070X3B11344",
    UUID: "9b582200-7765-11ed-8000-7cc2554dfdda",
    WakeUpType: WakeUpTypePowerSwitch (6),
    SKUNumber: "",
    Family: "",
}

smbios.SystemInformation {
    Manufacturer: "ASUS",
    ProductName: "System Product Name",
    Version: "System Version",
    SerialNumber: "System Serial Number",
    UUID: "a01149a6-1158-ab22-8d48-581122ab8d47",
    WakeUpType: WakeUpTypePowerSwitch (6),
    SKUNumber: "SKU",
    Family: "",
}
```

### （4）BaseboardInformation

<https://github.com/siderolabs/go-smbios/blob/v0.3.3/smbios/baseboard_information.go#L9-L31>

SMBIOS baseboard information

- Manufacturer
- Product
- Version
- SerialNumber
- AssetTag
- LocationInChassis
- BoardType

```go
smbios.BaseboardInformation {
    Manufacturer: "Supermicro",
    Product: "H12DSG-O-CPU",
    Version: "1.01A",
    SerialNumber: "VM22CS600902",
    AssetTag: "",
    LocationInChassis: "",
    BoardType: BoardTypeProcessorMemoryModule (10),
}

smbios.BaseboardInformation {
    Manufacturer: "ASUSTeK COMPUTER INC.",
    Product: "Pro WS W790-ACE",
    Version: "Rev 1.xx",
    SerialNumber: "230215393300040",
    AssetTag: "Default string",
    LocationInChassis: "Default string",
    BoardType: BoardTypeProcessorMemoryModule (10),
}
```

### （5）SystemEnclosure

<https://github.com/siderolabs/go-smbios/blob/v0.3.3/smbios/system_enclosure.go#L9-L21>

system enclosure

```go
smbios.SystemEnclosure {
    Manufacturer: "Supermicro",
    Version: "0123456789",
    SerialNumber: "C4180AM45AC0293",
    AssetTagNumber: "",
    SKUNumber: "",
}

smbios.SystemEnclosure {
    Manufacturer: "Intel Corporation",
    Version: "0.1",
    SerialNumber: "Default string",
    AssetTagNumber: "",
    SKUNumber: "Default string",
}
```

### （6）ProcessorInformation

<https://github.com/siderolabs/go-smbios/blob/v0.3.3/smbios/processor_information.go#L9-L46>

```go
[]smbios.ProcessorInformation len: 2, cap: 2, [
    {
        SocketDesignation: "CPU1",
        ProcessorManufacturer: "Advanced Micro Devices, Inc.",
        ProcessorVersion: "AMD EPYC 7742 64-Core Processor",
        MaxSpeed: 3400,
        CurrentSpeed: 2250,
        Status: 65,
        SerialNumber: "Unknown",
        AssetTag: "Unknown",
        PartNumber: "Unknown",
        CoreCount: 64,
        CoreEnabled: 64,
        ThreadCount: 128
    },{
        SocketDesignation: "CPU2",
        ProcessorManufacturer: "Advanced Micro Devices, Inc.",
        ProcessorVersion: "AMD EPYC 7742 64-Core Processor",
        MaxSpeed: 3400,
        CurrentSpeed: 2250,
        Status: 65,
        SerialNumber: "Unknown",
        AssetTag: "Unknown",
        PartNumber: "Unknown",
        CoreCount: 64,
        CoreEnabled: 64,
        ThreadCount: 128,
    },
]

[]smbios.ProcessorInformation len: 1, cap: 1, [
    {
        SocketDesignation: "CPU0",
        ProcessorManufacturer: "Intel(R) Corporation",
        ProcessorVersion: "Intel(R) Xeon(R) w7-2475X",
        MaxSpeed: 4000,
        CurrentSpeed: 2600,
        Status: 65,
        SerialNumber: "",
        AssetTag: "UNKNOWN",
        PartNumber: "",
        CoreCount: 20,
        CoreEnabled: 20,
        ThreadCount: 40,
    },
]
```

### （7）MemoryDevice

<https://github.com/siderolabs/go-smbios/blob/v0.3.3/smbios/memory_device.go#L14-L134>

```bash
[]smbios.MemoryDevice len: 32, cap: 36, [
    {
        PhysicalMemoryArrayHandle: 53,
        MemoryErrorInformationHandle: 60,
        TotalWidth: 72,
        DataWidth: 64,
        Size: 32767,
        FormFactor: FormFactorTSOP (9),
        DeviceSet: "",
        DeviceLocator: "P1-DIMMA1",
        BankLocator: "P0_Node0_Channel0_Dimm0",
        MemoryType: MemoryTypeLPDDR3 (26),
        TypeDetail: 128,
        Speed: 3200,
        Manufacturer: "Samsung",
        SerialNumber: "H0KE0003094462559C",
        AssetTag: "P1-DIMMA1_AssetTag (date:23/09)",
        PartNumber: "M393A8G40BB4-CWE",
        Attributes: 2,
        ExtendedSize: 0,
        ConfiguredMemorySpeed: 2933,
        MinimumVoltage: 1200,
        MaximumVoltage: 1200,
        ConfiguredVoltage: 1200,
    },{
        PhysicalMemoryArrayHandle: 53,
        MemoryErrorInformationHandle: 63,
        TotalWidth: 72,
        DataWidth: 64,
        Size: 32767,
        FormFactor: FormFactorTSOP (9),
        DeviceSet: "",
        DeviceLocator: "P1-DIMMA2",
        BankLocator: "P0_Node0_Channel0_Dimm1",
        MemoryType: MemoryTypeLPDDR3 (26),
        TypeDetail: 128,
        Speed: 3200,
        Manufacturer: "Samsung",
        SerialNumber: "H0KE000309446233CE",
        AssetTag: "P1-DIMMA2_AssetTag (date:23/09)",
        PartNumber: "M393A8G40BB4-CWE",
        Attributes: 2,
        ExtendedSize: 0,
        ConfiguredMemorySpeed: 2933,
        MinimumVoltage: 1200,
        MaximumVoltage: 1200,
        ConfiguredVoltage: 1200,
    },{
        PhysicalMemoryArrayHandle: 53,
        MemoryErrorInformationHandle: 66,
        TotalWidth: 72,
        DataWidth: 64,
        Size: 32767,
        FormFactor: FormFactorTSOP (9),
        DeviceSet: "",
        DeviceLocator: "P1-DIMMB1",
        BankLocator: "P0_Node0_Channel1_Dimm0",
        MemoryType: MemoryTypeLPDDR3 (26),
        TypeDetail: 128,
        Speed: 3200,
        Manufacturer: "Samsung",
        SerialNumber: "H0KE000309446252D2",
        AssetTag: "P1-DIMMB1_AssetTag (date:23/09)",
        PartNumber: "M393A8G40BB4-CWE",
        Attributes: 2,
        ExtendedSize: 0,
        ConfiguredMemorySpeed: 2933,
        MinimumVoltage: 1200,
        MaximumVoltage: 1200,
        ConfiguredVoltage: 1200,
    },
]

[]smbios MemoryDevice len: 8, cap: 8, [
    {
        PhysicalMemoryArrayHandle: 20,
        MemoryErrorInformationHandle: 65534,
        TotalWidth: 80,
        DataWidth: 64,
        Size: 32767,
        FormFactor: FormFactorTSOP (9),
        DeviceSet: "",
        DeviceLocator: "CPU0_DIMM_A1",
        BankLocator: "NODE 0",
        MemoryType: MemoryTypeDRAM|MemoryTypeLPDDR5 (34),
        TypeDetail: 128,
        Speed: 4800,
        Manufacturer: "Samsung",
        SerialNumber: "029836ED",
        AssetTag: "CPU0_DIMM_A1_AssetTag",
        PartNumber: "M321R4GA3BB6-CQKDG",
        Attributes: 2,
        ExtendedSize: 32768,
        ConfiguredMemorySpeed: 4800,
        MinimumVoltage: 1100,
        MaximumVoltage: 1100,
        ConfiguredVoltage: 1100
    }, {
        PhysicalMemoryArrayHandle: 20,
        MemoryErrorInformationHandle: 65534,
        TotalWidth: 80,
        DataWidth: 64,
        Size: 32767,
        FormFactor: FormFactorTSOP (9),
        DeviceSet: "",
        DeviceLocator: "CPU0_DIMM_A2",
        BankLocator: "NODE 0",
        MemoryType: MemoryTypeDRAM|MemoryTypeLPDDR5 (34),
        TypeDetail: 128,
        Speed: 4800,
        Manufacturer: "Samsung",
        SerialNumber: "029832FC",
        AssetTag: "CPU0_DIMM_A2_AssetTag",
        PartNumber: "M321R4GA3BB6-CQKDG",
        Attributes: 2,
        ExtendedSize: 32768,
        ConfiguredMemorySpeed: 4800,
        MinimumVoltage: 1100,
        MaximumVoltage: 1100,
        ConfiguredVoltage: 1100
    }, {
        PhysicalMemoryArrayHandle: 20,
        MemoryErrorInformationHandle: 65534,
        TotalWidth: 80,
        DataWidth: 64,
        Size: 32767,
        FormFactor: FormFactorTSOP (9),
        DeviceSet: "",
        DeviceLocator: "CPU0_DIMM_B1",
        BankLocator: "NODE 0",
        MemoryType: MemoryTypeDRAM|MemoryTypeLPDDR5 (34),
        TypeDetail: 128,
        Speed: 4800,
        Manufacturer: "Samsung",
        SerialNumber: "029836EB",
        AssetTag: "CPU0_DIMM_B1_AssetTag",
        PartNumber: "M321R4GA3BB6-CQKDG",
        Attributes: 2,
        ExtendedSize: 32768,
        ConfiguredMemorySpeed: 4800,
        MinimumVoltage: 1100,
        MaximumVoltage: 1100,
        ConfiguredVoltage: 1100
    },
]
```

### bugfix

修复 memory 类型错误

```golang
type MemoryDeviceExtendedSize uint16

# ->

type MemoryDeviceExtendedSize uint32
```

## 参考资料

项目

- <https://github.com/siderolabs/go-smbios>

资料

- <https://blog.51cto.com/u_12968/6990334>
- <https://blog.csdn.net/zhoudaxia/article/details/5919699>
- <https://blog.csdn.net/zhoudaxia/article/details/5919871>
- <https://blog.csdn.net/zhoudaxia/article/details/5919967>

- <https://blog.51cto.com/u_16099321/8029247>