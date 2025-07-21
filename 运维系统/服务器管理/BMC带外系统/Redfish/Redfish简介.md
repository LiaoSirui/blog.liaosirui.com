## Redfish

BMC Redfish 指的是基于 Redfish API 的 BMC（Baseboard Management Controller，主板管理控制器）实现

Redfish 是一种基于 HTTPs 服务的管理标准，利用 RESTful 接口实现设备管理。每个 HTTPs 操作都以 UTF-8 编码的 JSON 格式（JSON 是一种 key-value 对的数据格式）提交或返回一个资源或结果，就像 Web 应用程序向浏览器返回 HTML 一样。该技术具有降低开发复杂性，易于实施、易于使用而且提供了可扩展性优势，为设计灵活性预留了空间

```bash
curl -i -k --request POST -H "Content-Type: application/json" -d '{"UserName" : "xxxxxxx","Password" : "xxxxx"}' ${http协议}://${带外ip地址}/redfish/v1/SessionService/Sessions && echo
```

- python-redfish-library: A python library used by a number of tools <https://github.com/DMTF/python-redfish-library>
- Redfish-Event-Listener: An example client for testing and implementing EventService handlers <https://github.com/DMTF/Redfish-Event-Listener>
- Redfish-Tacklebox: A collection of common utilities for managing redfish servers <https://github.com/DMTF/Redfish-Tacklebox>

## 参考资料

- <https://blog.csdn.net/sinat_36458870/article/details/124728301>
- <https://www.ctyun.cn/developer/article/448967321534533>
