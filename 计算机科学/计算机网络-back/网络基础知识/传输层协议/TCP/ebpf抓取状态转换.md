## 观测 TCP 状态转移

环境准备：用一个 nginx 作为 server（`server_ip:server_port`），同时用 curl 作为 client

### inet_sock_set_state

内核提供了一个 tracepoint: inet_sock_set_state

这个 tracepoint 会在 TCP 状态发生变化的时候被调用，于是就有了 TCP 状态转移的观测点

用 ebpf/libbpf 实现：

```c
SEC("tp_btf/inet_sock_set_state")
int BPF_PROG(trace_inet_sock_set_state, struct sock *sk, 
        int oldstate, int newstate){
    const int type = BPF_CORE_READ(sk,sk_type);
    if(type != SOCK_STREAM){//1
        return 0;
    }
    const struct sock_common skc = BPF_CORE_READ(sk,__sk_common);
    const struct inet_sock *inet = (struct inet_sock *)(sk);
    return track_state((long long)sk,&skc,inet,oldstate,newstate);
}

```

监听到状态转移事件后就可以从中提取这个连接的 4 元组

```c
static int track_state(long long skaddr,const struct sock_common *skc,
        const struct inet_sock *inet,
        int oldstate, int newstate){
    __u32 dip = (BPF_CORE_READ(skc,skc_daddr));  
    __u16 dport = (BPF_CORE_READ(skc,skc_dport)); 
    __u32 sip = (BPF_CORE_READ(inet,inet_saddr));
    __u16 sport = (BPF_CORE_READ(inet,inet_sport));
    return judge_side(skaddr,dip, dport, sip, sport,oldstate,newstate);
}
```

然后依据 4 元组判断是哪个 side

```c
static int judge_side(long long skaddr,__u32 dip,__u16 dport,__u32 sip, __u16 sport,
    int oldstate, int newstate){
    enum run_mode m = ENUM_unknown;
    // server might bind to INADDR_ANY rather than just server_ip
    if((sip == server_ip || sip == INADDR_ANY) && sport == server_port){   
        m = ENUM_server;    
        fire_sock_release_event(m,oldstate,newstate);
    }
    else if(dip == server_ip && dport == server_port){    
        m = ENUM_client;   
        fire_sock_release_event(m,oldstate,newstate);
    }
    return 0;
}
```

判断完毕后，将事件发送到用户空间

```c
static void fire_sock_release_event(enum run_mode mode, int oldstate, int newstate){
    struct event *e ;
    e = bpf_ringbuf_reserve(&rb, sizeof(*e), 0);
    if (!e){
        return;
    }
    e->mode = mode;
    e->oldstate = oldstate;
    e->newstate = newstate;
    e->ts = bpf_ktime_get_ns();
    bpf_ringbuf_submit(e, 0);
}
```

用户空间打印出来即可

```c
static int handle_event(void *ctx, void *data, size_t data_sz){
    const struct event *e = data;
    fprintf(stderr, "ts:%llu:%s:%s:%s\n",
        e->ts,mode2str(e->mode),state2str(e->oldstate),state2str(e->newstate));
    return 0;
}
```

### inet_timewait_sock

在内核源代码中搜索一下相关文件会发现，一个连接有多个 `struct` 来表示。对于 `sock` 来说，确实 `FIN_WAIT2` 后就 `CLOSE` 了，然后把 `time_wait` 委托给 `inet_timewait_sock` 这个 `struct` 来管理了。具体过程可以查看 `tcp_time_wait` 这个函数

查看这个文件 `inet_timewait_sock.h` 我们大概就能找到一个连接进入和离开 `time_wait` 状态需要调用的函数了

进入我们采用fexit，可以获得生成的 `inet_timewait_sock` 的结构体，便于和离开时作对比：

```c
SEC("fexit/inet_twsk_alloc")
int BPF_PROG(inet_twsk_alloc,const struct sock *sk,struct inet_timewait_death_row *dr,
                       const int state,struct inet_timewait_sock *tw) {
    const int type = BPF_CORE_READ(sk,sk_type);
    if(type != SOCK_STREAM){//1
        return 0;
    }
    const struct sock_common skc = BPF_CORE_READ(sk,__sk_common);
    const struct inet_sock *inet = (struct inet_sock *)(sk);
    const char oldstate = (BPF_CORE_READ(&skc,skc_state));
    bpf_printk("tw_aloc,skaddr:%u,skcaddr:%u,twaddr:%u,oldstate:%s,newstate:%s",
        sk,&skc,tw,state2str(oldstate),state2str(state));
    track_state((long long)sk,&skc,inet,oldstate,state);
    return 0;
}
```

离开采用传统的 kprobe 即可

```c
SEC("kprobe/inet_twsk_put")
int BPF_KPROBE(kprobe_inet_put,struct inet_timewait_sock *tw) {
    const struct sock_common skc = BPF_CORE_READ(tw,__tw_common);
    const int family = BPF_CORE_READ(&skc,skc_family);
    if(family != AF_INET){
        return 0;
    }
    // 省略 tw 对比代码
    __u32 dip = (BPF_CORE_READ(&skc,skc_daddr));  
    __u16 dport = (BPF_CORE_READ(&skc,skc_dport)); 
    __u32 sip = (BPF_CORE_READ(&skc,skc_rcv_saddr));
    __u16 sport = bpf_htons(BPF_CORE_READ(&skc,skc_num));
    return judge_side((long long)tw,dip, dport, sip, sport,oldstate,TCP_CLOSE);
}
```



### 可视化

用 Python 画一下

```python
plt.text(start, 1.20, f'Server State Changes',fontsize=15)
plt.plot(sx[:2], sy[:2], colors[0] + '-')   
idx = timestamps.index(sx[1])
msg = old_states[idx]
plt.text(start, sy[0] + 0.01, f'({start}:{msg})',fontsize=fontsize)
plt.plot(start, sy[0], colors[0] + 's', alpha=0.5,markersize = markersize) 
for i in range(1, len(sx)-1):
    upward = (i/25) 
    plt.plot(sx[i:i+2], [sy[i]+upward,sy[i+1]+upward], colors[i] + '-')  
    idx = timestamps.index(sx[i])
    msg = new_states[idx]
    plt.text(sx[i], sy[i]+upward+0.01, f'({sx[i]}:{msg})',fontsize=fontsize)
    plt.plot(sx[i], sy[i]+upward, colors[i] + 's', alpha=0.5,markersize = markersize) 

plt.show()

```

注：time_wait 状态占用时间非常长，影响展示，这里微调了一下

## 参考资料

- <https://mp.weixin.qq.com/s/7FlB56iH6h9dYOxcGoAIEA>
- <https://mp.weixin.qq.com/s/46AGNY_9iMQR1xAyeZhhLg>