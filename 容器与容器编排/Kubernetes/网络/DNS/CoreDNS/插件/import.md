官方文档：<https://coredns.io/plugins/import/>

如果有多个 zone，每个 zone 都有相同的基础配置，可以使用 import 指令，如：

```corefile
liaosirui.com:53 {
    forward liaosirui.com 47.108.210.208
    log
    whoami
    errors
    prometheus 192.168.100.100:9253
    bind 192.168.100.100
    cache {
        success 10240 600 60
        denial 5120 60 5
    }
}

google.com:53 {
    forward google.com 8.8.8.8 9.9.9.9
    log
    whoami
    errors
    prometheus 192.168.100.100:9253
    bind 192.168.100.100
    cache {
        success 10240 600 60
        denial 5120 60 5
    }
}

example.org {
    file /home/coredns/conf/example.org
    log
    whoami
    errors
    prometheus 192.168.100.100:9253
    bind 192.168.100.100
    cache {
        success 10240 600 60
        denial 5120 60 5
    }
}

```

可以简化成这样：

```corefile
(basesnip) {
    log
    whoami
    errors
    prometheus 192.168.100.100:9253
    bind 192.168.100.100
    cache {
        success 10240 600 60
        denial 5120 60 5
    }
}

liaosirui.com:53 {
    forward liaosirui.com 47.108.210.208
    import basesnip
}

google.com:53 {
    forward google.com 8.8.8.8 9.9.9.9
    import basesnip
}

example.org {
    file /home/coredns/conf/example.org
    import basesnip
}

```

