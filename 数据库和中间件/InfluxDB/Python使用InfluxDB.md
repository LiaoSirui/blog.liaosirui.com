
## 环境准备

安装依赖包：

```bash
pip3 install influxdb==5.3.1
```

## 连接

```python
from influxdb import InfluxDBClient

client = InfluxDBClient('10.203.25.106', 8086, timeout=10) 
# timeout 超时时间 10秒

client = InfluxDBClient('172.17.0.1', 8086, ssl=False, retries=3, timeout=10) 
```

说明：

```python
class influxdb.InfluxDBClient(host=u'localhost', port=8086, username=u'root', password=u'root', database=None, ssl=False, verify_ssl=False, timeout=None, retries=3, use_udp=False, udp_port=4444, proxies=None)

参数

host (str) – 用于连接的InfluxDB主机名称，默认‘localhost’

port (int) – 用于连接的Influxport端口，默认8086

username (str) – 用于连接的用户名，默认‘root’

password (str) – 用户密码，默认‘root’

database (str) – 需要连接的数据库，默认None

ssl (bool) – 使用https连接，默认False

verify_ssl (bool) – 验证https请求的SSL证书，默认False

timeout (int) – 连接超时时间(单位：秒)，默认None,

retries (int) – 终止前尝试次数（number of retries your client will try before aborting, defaults to 3. 0 indicates try until success）

use_udp (bool) – 使用UDP连接到InfluxDB默认False

udp_port (int) – 使用UDP端口连接，默认4444

proxies (dict) – 为请求使用http（s）代理，默认 {}
```

## 操作

- 获取数据库列表

```python
print('获取数据库列表：')

database_list = client.get_list_database()

print(database_list)
```

- 创建数据库

```python
print('\n创建数据库')

client.create_database('mytestdb')

print(client.get_list_database())
```

- 切换数据库

```python
print('\n切换至数据库（切换至对应数据库才可以操作数据库对象)\n')

client.switch_database('mytestdb')
```

- 插入表数据

```python
print('插入表数据\n')

for i in range(0, 10):
    json_body = [
        {
            "measurement": "table1",
            "tags": {
                "stuid": "stuid1"
            },
            # "time": "2018-05-16T21:58:00Z",
            "fields": {
                "value": float(random.randint(0, 1000))
            }
        }
    ]

client.write_points(json_body)
```

- 查看表

```python
print('查看数据库所有表\n')
tables = client.query('show measurements;')
```

- 查询表记录

```python
print('查询表记录')
rows = client.query('select value from table1;')
print(rows)
```

```text
query(query, params=None, epoch=None, expected_response_code=200, database=None, raise_errors=True, chunked=False, chunk_size=0)

参数:

query (str) – 真正执行查询的字符串

params (dict) – 查询请求的额外参数，默认{}

epoch (str) – response timestamps to be in epoch format either ‘h’, ‘m’, ‘s’, ‘ms’, ‘u’, or ‘ns’,defaults to None which is RFC3339 UTC format with nanosecond precision

expected_response_code (int) – 期望的响应状态码，默认 200

database (str) – 要查询的数据库，默认数据库

raise_errors (bool) – 查询返回错误时，是否抛出异常，默认

chunked (bool) – Enable to use chunked responses from InfluxDB. With chunked enabled, one ResultSet is returned per chunk containing all results within that chunk

chunk_size (int) – Size of each chunk to tell InfluxDB to use.

返回数据查询结果集
```

- 删除表

```python
print('\n删除表\n')
client.drop_measurement('table1')
```

- 删除数据库

```python
print('删除数据库\n')

client.drop_database('mytestdb')
```
