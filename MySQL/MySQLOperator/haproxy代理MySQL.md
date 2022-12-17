haproxy可以通过 **TCP协议** 来代理MySQL。但是两个问题必须考虑：

1. 后端MySQL的健康检查问题
2. 如何保证事务的持久性(同一个事务中的语句路由到同一个后端)

## 健康检查问题

haproxy默认已支持MySQL的健康检查，对应的指令为`option mysql-check`，浏览下该指令语法：

```
option mysql-check [ user <username> [ post-41 ] ]
```

其中user是连接MySQL时使用的用户名，post-41是发送一种名为post v4.1的检查包。整个过程只检查haproxy能否连接到MySQL。

有时候，仅仅检查MySQL服务的连通性是不够的，例如想检查某个数据库是否存在，检查主从复制是否正常，节点是否read_only，某个slave是否严重落后于master等等。

目前为止，MySQL组复制(MGR)、Galera已经逐渐普及，haproxy更无法检查这两类集群的合理性。

这时候需要使用外部脚本，自定义检查内容并将检查结果报告给haproxy。当然，借助脚本实现一些自定义的内部操作也是可以的。

因为haproxy对http的支持最完善，因此采用httpchk的健康检查方式，所以使用外部健康检查脚本时，检查结果必须要转换为haproxy能理解的http状态码报告。一般情况下，健康的结果使用http 200状态码表示，不健康的结果使用Http 503来表示 。

### MySQL健康检查脚本示例

要检查数据库mytest是否存在，外部的脚本(假设脚本名为/usr/bin/mysqlchk.sh)内容大概如下：

```
#!/bin/bash

# $0:/usr/bin/mysqlchk.sh

mysql_port=3306
mysql_host="localhost"
chk_mysqluser="haproxychk"
chk_mysqlpasswd="haproxychkpassword1!"
mysql=/usr/bin/mysql
to_test_db=mytest

### check 
mysql -u${chk_mysqluser} -p${chk_mysqlpasswd} -h${mysql_host} -P${mysql_port} \ 
-e "show databases;" 2>/dev/null | grep "${to_test_db}" &>/dev/null

### translate the result to report to haproxy 
if [ $? -eq 0 ];then
    # mysql is healthy, return http 200 
    /bin/echo -en "HTTP/1.1 200 OK\r\n" 
    /bin/echo -en "Content-Type: Content-Type: text/plain\r\n" 
    /bin/echo -en "Connection: close\r\n" 
    /bin/echo -en "\r\n" 
    /bin/echo -en "MySQL is running and $to_test_db exists.\r\n" 
    /bin/echo -en "\r\n" 
    sleep 0.1
    exit 0
else
    # mysql is unhealthy, return http 503 
    /bin/echo -en "HTTP/1.1 503 Service Unavailable\r\n" 
    /bin/echo -en "Content-Type: Content-Type: text/plain\r\n" 
    /bin/echo -en "Connection: close\r\n" 
    /bin/echo -en "\r\n" 
    /bin/echo -en "MySQL is down or $to_test_db not exists.\r\n" 
    /bin/echo -en "\r\n" 
    exit 1
fi
```

执行权限：

```bash
chmod +x /usr/bin/mysqlchk.sh
```

然后，将其放进xinetd中进行管理。

```
yum -y install xinetd

cat /etc/xinetd.d/mysqlchk
# default: on
# description: /usr/bin/mysqlchk.sh
service mysqlchk
{
        disable = no
        flags           = REUSE
        socket_type     = stream
        type            = UNLISTED
        port            = 9200
        wait            = no
        user            = nobody
        server          = /usr/bin/mysqlchk.sh
        # server_args = arguments pass to mysqlchk.sh
        log_on_failure  += USERID
        only_from       = 0.0.0.0/0
        per_source      = UNLIMITED
```

然后向/etc/services中添加端口和服务名映射关系：

```
cat >>/etc/services<<eof
mysqlchk      9200/tcp        #mysqlchk
eof
```

最后重新启动xinetd：

```undefined
service xinetd restart
```

然后配置haproxy，大概内容如下：

```
listen mysql-cluster 0.0.0.0:3306
mode tcp
balance roundrobin
option httpchk            # 注意此处是httpchk，不是mysql-check
server db01 10.4.29.100:3306 check port 9200 inter 12000 rise 3 fall 3
server db02 10.4.29.99:3306 check port 9200 inter 12000 rise 3 fall 3
server db03 10.4.29.98:3306 check port 9200 inter 12000 rise 3 fall 3
```

这种检查方式已经被percona官方采纳并进行了完善，放进了percona-xtradb-cluster包中作为haproxy+PXC的健康检查脚本。

根据这种模式，可以让haproxy检查更多类型的服务。

## 事务持久性问题

haproxy代理MySQL的时候，事务持久性的问题必须解决。这个事务持久性不是ACID的D(持久性, Durability)，而是transaction persistent，这里简单描述一下此处的事务持久性。

客户端显式开启一个事务，然后执行几个操作，然后提交或回滚。

```
start transaction
update1...
update2...
insert3...
commit
```

如果使用代理软件(例如haproxy)对MySQL进行代理，必须要保证这5个语句全都路由到同一个MySQL节点上，即使后端的MySQL采用的多主模型(组复制、Galera都提供多主模型)，否则事务中各语句分散，轻则返回失败，重则数据不一致、提交混乱。

这就是transaction persistent的概念：让同一个事务路由到同一个后端节点。

haproxy如何保证事务持久性？对于非MySQL协议感知的代理(lvs/nginx/haproxy等)，要保证事务持久性，只能通过间接的方法实现， **比较通用的方法是在代理软件上监听不同端口** 。具体思路如下：

* 1.在haproxy上监听不同端口，例如3307端口的请求作为写端口，3306端口的请求作为读端口。
* 2.从后端MySQL节点中选一个节点(只能是一个)作为逻辑写节点，haproxy将3307端口的请求全都路由给这个节点。
* 3.可以在haproxy上配置备用写节点(backup)，但3307端口在某一时刻，必须只能有一个写节点。

这样能保证事务的持久性，也能解决一些乐观锁问题。但是，如果后端是多主模型的Galera或MySQL组复制，这样的代理方式将强制变为单主模型，虽然是逻辑上的强制。当然，这并非什么问题，至少到目前为止的开源技术，都建议采用单主模型。

以下是haproxy保证事务持久性的配置示例：

```
listen  haproxy_3306_read_multi
        bind *:3306
        mode tcp
        timeout client  10800s
        timeout server  10800s
        balance leastconn
        option httpchk
        option allbackups
        default-server port 9200 inter 2s downinter 5s rise 3 fall 2 slowstart 60s maxconn 64 maxqueue 128 weight 100
        server galera1 192.168.55.111:3306 check
        server galera2 192.168.55.112:3306 check
        server galera3 192.168.55.113:3306 check
 
listen  haproxy_3307_write_single
        bind *:3307
        mode tcp
        timeout client  10800s
        timeout server  10800s
        balance leastconn
        option httpchk
        option allbackups
        default-server port 9200 inter 2s downinter 5s rise 3 fall 2 slowstart 60s maxconn 64 maxqueue 128 weight 100
        server galera1 192.168.55.111:3306 check
        server galera2 192.168.55.112:3306 check backup
        server galera3 192.168.55.113:3306 check backup
```

上面的配置通过3306端口和3307端口进行读写分离，并且在负责写的3307中只有一个节点可写，其余两个节点作为backup节点。

对于MySQL的负载来说，更建议采用MySQL协议感知的程序来实现，例如mysql router，proxysql，maxscale，mycat等等数据库中间件。


<br />


https://www.percona.com/doc/kubernetes-operator-for-pxc/haproxy-conf.html