`requests`只能发送同步请求；`aiohttp`只能发送异步请求；`httpx`既能发送同步请求，又能发送异步请求

httpx:

- 文档：<https://www.python-httpx.org/>
- GitHub 仓库：<https://github.com/encode/httpx/>

所谓的同步请求，是指在单进程单线程的代码中，发起一次请求后，在收到返回结果之前，不能发起下一次请求。所谓异步请求，是指在单进程单线程的代码中，发起一次请求后，在等待网站返回结果的时间里，可以继续发送更多请求

httpx 是一个几乎继承了所有 requests 的特性并且支持 "异步" http 请求的开源库。简单来说，可以认为 httpx 是强化版 requests

httpx 的同步模式与 requests 代码重合度99%，只需要把`requests`改成`httpx`即可正常运行

```python
import httpx
import asyncio


async def main():
    async with httpx.AsyncClient() as client:
        resp = await client.post('http://xxx/query',
                                 json={'ts': '2020-01-20 13:14:15'})
        result = resp.json()
        print(result)


asyncio.run(main())
```

