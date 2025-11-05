## 配置 robots.txt

禁止所有爬虫

```bash
User-agent: *
Disallow: /
```

其他的 User-Agent

```bash
User-agent:  *      // 通用爬虫, 即如果没有指定, 则所有爬虫都应遵守本节规则
User-agent:  Baiduspider // 百度爬虫
User-Agent:  Googlebot // 谷歌爬虫
User-agent:  Bingbot  // Bing 爬虫
User-Agent:  360Spider // 360 爬虫
User-Agent:  Yahoo!  Slurp // 雅虎爬虫
User-Agent:  Sogouspider // 搜狗爬虫
User-Agent:  Yisouspider // 神马搜索爬虫
User-agent: Twitterbot // twitter 爬虫
```

## 参考资料

- <https://gist.github.com/zhaokuohaha/fa386d2996f978334fd55094609d6c89>