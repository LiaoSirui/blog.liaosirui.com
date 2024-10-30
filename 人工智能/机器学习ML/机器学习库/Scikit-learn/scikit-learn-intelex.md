## Intel(R) Extension for Scikit-learn

Intel (R) Extension for Scikit-learn 是一个免费的人工智能加速器软件，旨在为现有的 Scikit-learn 代码提供超过 10-100 倍的加速。这个加速是通过向量指令、AI 硬件特定的内存优化、线程和针对所有即将推出的 Intel (R) 平台的优化来实现的

- <https://github.com/intel/scikit-learn-intelex>
- <https://intel.github.io/scikit-learn-intelex/2024.6/quick-start.html>

需要的 CPU x86 指令集

- SSE2
- SSE4.2
- AVX2
- AVX512

## 使用

检查 CPU 是否支持

```bash
#!/bin/bash

# 定义一个函数来检查特定的 CPU 标志
check_flag() {
    flag=$1
    echo "====================="
    search_cpu_res=$(lscpu | tr ' ' '\n' | grep "$flag")
    if [ "$(echo "${search_cpu_res}" |grep -c "${flag}")" -eq 0 ]; then
        echo "CPU does not support $flag"
    else
        echo "CPU supports $flag"
        echo -e "CPU Flags: \n${search_cpu_res}"
    fi
    echo "====================="
}

# 检查 SSE2
check_flag "sse2"

# 检查 SSE4.2
check_flag "sse4_2"

# 检查 AVX2
check_flag "avx2"

# 检查 AVX512
check_flag "avx512"
```

安装

```bash
pip install scikit-learn-intelex
```

CPU 运行

```python
import numpy as np
from sklearnex import patch_sklearn
patch_sklearn()

from sklearn.cluster import DBSCAN

X = np.array([[1., 2.], [2., 2.], [2., 3.],
            [8., 7.], [8., 8.], [25., 80.]], dtype=np.float32)
clustering = DBSCAN(eps=3, min_samples=2).fit(X)
```

或者

```bash
python -m sklearnex my_application.py
```

## 运行速度对比

```python
import time

import numpy as np
from sklearn.cluster import DBSCAN

start = time.time()
X = np.array([[1., 2.], [2., 2.], [2., 3.],
            [8., 7.], [8., 8.], [25., 80.]], dtype=np.float32)
clustering = DBSCAN(eps=3, min_samples=2).fit(X)
end = time.time()

print('运行时间为：{}秒'.format(end-start))
print('运行时间为：{}毫秒'.format((end-start) * 1000))
```

分别运行

```bash
# 使用 Intel(R) Extension for Scikit-learn
python -m sklearnex my_application.py

# 普通运行
python my_application.py
```

运行结果

```
# python -m sklearnex my_application.py
Intel(R) Extension for Scikit-learn* enabled (https://github.com/intel/scikit-learn-intelex)
运行时间为：0.011353254318237305秒
运行时间为：11.353254318237305毫秒

# python my_application.py
运行时间为：0.06251788139343262秒
运行时间为：62.51788139343262毫秒
```

