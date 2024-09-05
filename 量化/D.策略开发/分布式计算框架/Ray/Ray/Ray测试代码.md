测试并行读取文件

```python
import pandas as pd
import glob
import ray
import pyarrow as pa
import time
 
ray.shutdown()
ray.init(num_cpus=40, object_store_memory=1024 * 1024 * 1024 * 20)
 
@ray.remote
def read(f):
    with pa.memory_map(f, 'rb') as source:
        table = pa.ipc.RecordBatchFileReader(source).read_all()
        if "high" not in table.column_names:
            # print(f)
            return None
 
        trading_day = table["trading_day"].to_pandas()
        high = table["high"].to_pandas()
        low = table["low"].to_pandas()
        x = (high / low).groupby(trading_day).apply(lambda x: x.std())
 
        instrument = f.rsplit("/", 1)[1].rsplit(".", 1)[0]
 
        df = pd.DataFrame({
            "factor": x,
            "date": pd.to_datetime(x.index.astype(str), format='%Y%m%d'),
            "instrument": instrument
        })
        # use pyarrow, may be faster?
        return pa.Table.from_pandas(df)
 
files = glob.glob("/data/high_freq/level2_bar1m_CN_STOCK_A_arrow/2020/*.arrow")
futures = [read.remote(f) for f in files]
 
s = time.time()
results = ray.get(futures)
print(time.time() - s, len(results))
 
s = time.time()
with pa.OSFile('/data/test/result.arrow', 'wb') as sink:
    with pa.RecordBatchFileWriter(sink, results[0].schema) as writer:
        for table in results:
            if table is None:
                continue
            writer.write_table(table)
print(time.time() - s)
```

并行读取文件 demo2

```python
import pandas as pd
import glob
import ray
import pyarrow as pa
import time
 
ray.shutdown()
ray.init("ray://ray-head.ray.svc.cluster.local:10001")
  
@ray.remote
def read(f):
    with pa.memory_map(f, 'rb') as source:
        table = pa.ipc.RecordBatchFileReader(source).read_all()
        if "high" not in table.column_names:
            # print(f)
            return None
  
        trading_day = table["trading_day"].to_pandas()
        high = table["high"].to_pandas()
        low = table["low"].to_pandas()
        x = (high / low).groupby(trading_day).apply(lambda x: x.std())
  
        instrument = f.rsplit("/", 1)[1].rsplit(".", 1)[0]
  
        df = pd.DataFrame({
            "factor": x,
            "date": pd.to_datetime(x.index.astype(str), format='%Y%m%d'),
            "instrument": instrument
        })
        # use pyarrow, may be faster?
        return pa.Table.from_pandas(df)
  
files = glob.glob("/data/high_freq/level2_bar1m_CN_STOCK_A_arrow/2014/*.arrow")
 
futures = [read.remote(f) for f in files]
 
s = time.time()
results = ray.get(futures)
print(time.time() - s, len(results))
```

