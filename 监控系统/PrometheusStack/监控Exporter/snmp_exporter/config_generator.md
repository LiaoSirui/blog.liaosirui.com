SNMP Exporter Config Generator <https://github.com/prometheus/snmp_exporter/tree/main/generator>

```bash
dnf install -y gcc make net-snmp net-snmp-utils net-snmp-libs net-snmp-devel golang-bin

# go install github.com/prometheus/snmp_exporter/generator@v0.30.1
go install github.com/prometheus/snmp_exporter/generator@latest
```

确保 SNMP 导出器配置生成器的版本与生成 `snmp.yml` 的 SNMP 导出器版本一致

配置生成器从 **`generator.yml`** 中读取简化的收集指令并把相应的配置写入 **`snmp.yml`** 。 **`snmp_exporter`** 可二进制执行文件仅使用 **`snmp.yml`** 文件从开启了 **`snmp`** 的设备收集数据。



生成配置

```bash
export MIBDIRS=./mibs
/root/go/bin/generator --fail-on-parse-errors generate
```

建议**不同类型的设备**都有一个目录，其中包含不同设备类型的 **`mibs`** 目录、生成器可执行文件和 **`generator.yml`** 配置文件。这是为了避免 **`MIB`** 定义中的名称空间冲突。仅在设备的 **`mibs`** 目录中保留所需的 **`MIB文件`** 。

```bash
./generator generate \
-m huawei/mibs \
-m /opt/snmp_exporter/generate/mibs \
-g huawei/generator.yml \
-o /opt/snmp_exporter/generate/huawei/snmp.yml
```

## 参考资料

- <https://luanxinchen.github.io/2021/01/18/snmp-custom-metrics/>
- <https://zhuanlan.zhihu.com/p/675276335>
- <https://blog.csdn.net/wsyzxss/article/details/120666622>

- <https://sbcode.net/prometheus/snmp-generate-huawei/>