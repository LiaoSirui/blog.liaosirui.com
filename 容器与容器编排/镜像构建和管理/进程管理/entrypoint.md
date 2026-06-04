用 Shell 来实现 entrypoint

```bash
if [ -z "$*" ]; then
  echo "\
  main entrypoint
"
  exec bash --login
else
  exec "$@"
fi
# 判断 "是否没有传入任何参数"，如果没有参数则执行 then 后面的代码
```

