## PMEM 简介

持久内存 (PMEM) 是驻留在内存总线上的固态高性能按字节寻址内存设备

PMEM 位于内存总线上，支持像 DRAM 一样访问数据，这意味着它具备与 DRAM 相当的速度和延迟，而且兼具 NAND 闪存的非易失性

持久内存技术的示例：

- NVDIMM（非易失性双列直插式内存模块）
- Intel 3D XPoint DIMM（也称为 Optane DC 持久内存模块）

### 持久内存优势

- 访问延迟低于闪存 SSD 的访问延迟
- 吞吐量提高，超过闪存存储
- 比 DRAM 便宜。
- PMEM 可缓存。与 PCIe 互连相比，这是一个巨大的优势，PCIe 互连不能在 CPU 中缓存
- 可实时访问数据；支持对大型数据集进行超高速访问。
- 断电后，数据仍保留在内存中，例如闪存

## 参考资料

- <https://www.netapp.com/zh-hans/data-storage/what-is-persistent-memory/>