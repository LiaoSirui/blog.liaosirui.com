准入控制器是在对象持久化之前用于对 Kubernetes API Server 的请求进行拦截的代码段，在请求经过身份验证和授权之后放行通过

时序图如下所示：

![image-20230506105627557](.assets/Admission/image-20230506105627557.png)

准入控制存在两种 WebHook

- 变更准入控制 MutatingAdmissionWebhook：Mutating 控制器可以修改他们处理的资源对象
- 验证准入控制 ValidatingAdmissionWebhook：如果任何一个阶段中的任何控制器拒绝了请求，则会立即拒绝整个请求，并将错误返回给最终的用户

执行的顺序是先执行 MutatingAdmissionWebhook 再执行 ValidatingAdmissionWebhook

