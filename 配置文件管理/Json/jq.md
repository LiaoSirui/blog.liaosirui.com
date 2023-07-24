## jq 简介

jq 是一款基于命令行处理 JSON 数据的工具

其可以接受标准输入，命令管道或者文件中的 JSON 数据，经过一系列的过滤器 (filters) 和表达式的转后形成我们需要的数据结构并将结果输出到标准输出中，从而帮助很好的解析 json 数据

## 安装

### 编译安装

```bash
git clone https://github.com/stedolan/jq.git

cd jq
autoreconf -i
./configure --disable-maintainer-mode
make && make install
```

## 示例

从环境变量读取

```bash
gpu_ip=10.16.153.20

cat ${orion_file} | \
  jq -r \
  --arg gpu_ip "${gpu_ip}" \
  '[ .data.items[]|select(.DeviceMeta.device_ip == $gpu_ip) ] | .[].DeviceID'
```



## 参考文档

- <https://www.cnblogs.com/sunsky303/p/16437766.html>

- <https://hellogitlab.com/OS/Centos/json_tool_jq.html>

- <https://gitbook.curiouser.top/origin/linux-jq.html>
