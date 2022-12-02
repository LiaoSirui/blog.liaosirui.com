htop 的配置文件：`~/.htoprc` 或者 `~/.config/htop/htoprc`

```
hide_userland_threads=1
```

其他配置参考

```
# Beware! This file is rewritten by htop when settings are changed in the interface.
# # The parser is also very primitive, and not human-friendly.
fields=0 48 17 18 38 39 40 2 46 47 49 1 
sort_key=1
sort_direction=1
hide_threads=0
hide_kernel_threads=1
hide_userland_threads=0
shadow_other_users=0
show_thread_names=0
show_program_path=1
highlight_base_name=0
highlight_megabytes=1
highlight_threads=1
tree_view=0
header_margin=1
detailed_cpu_time=0
cpu_count_from_zero=0
update_process_names=0
account_guest_in_cpu_meter=0
color_scheme=0
delay=15
left_meters=LeftCPUs Memory Swap 
left_meter_modes=1 1 1 
right_meters=RightCPUs Tasks LoadAverage Uptime 
right_meter_modes=1 2 2 2 
```

使用详解：<https://cloud.tencent.com/developer/article/1115041>

使用详解：<https://linux.cn/article-3141-1.html>

https://www.cnblogs.com/programmer-tlh/p/11726016.html

https://www.cnblogs.com/liuyansheng/p/6346523.html

