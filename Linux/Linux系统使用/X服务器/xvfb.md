xvfb-run - 运行在一个虚拟的 X 服务器环境中的指定的 X 客户端或命令

生成网站缩略图

```bash
xvfb-run --server-args="-screen 0, 1024x768x24" cutycapt --url=http://www.sina.com.cn --out=localfile1.png --body-string=utf-8
```

参考：<https://404story.com/labrary/1043.html>