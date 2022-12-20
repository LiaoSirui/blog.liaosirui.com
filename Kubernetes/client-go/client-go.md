https://www.huweihuang.com/kubernetes-notes/develop/client-go.html

client-go是一个调用kubernetes集群资源对象API的客户端，即通过client-go实现对kubernetes集群中资源对象（包括deployment、service、ingress、replicaSet、pod、namespace、node等）的增删改查等操作。大部分对kubernetes进行前置API封装的二次开发都通过client-go这个第三方包来实现。

 client-go官方文档：https://github.com/kubernetes/client-go