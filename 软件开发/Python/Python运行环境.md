建议优化

```bash
ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1
```

Python 禁用 stdout 缓冲（print 输出延迟）

```bash
python3 -u xxx

-u     : force the stdout and stderr streams to be unbuffered;
         this option has no effect on stdin; also PYTHONUNBUFFERED=x
```

