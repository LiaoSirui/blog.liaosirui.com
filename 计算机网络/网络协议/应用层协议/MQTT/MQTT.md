## MQTT

MQTT 是一种基于标准的消息传递协议或规则集，用于机器对机器的通信

## MQTT over QUIC

![mqtt-over-quic](./.assets/MQTT/mqtt-over-quic.82iS7R0q.png)

QUIC 桥接具有以下独特的优势和特性：

- 多流传输 ： 自动创建 主题-流 的配对，避免 TCP 的队头阻塞问题。
- 混合桥接模式 ： 能够根据 QUIC 传输层的连接情况自动降级到 TCP 以保证通道可用。
- QoS 消息优先传输：能够给 QoS 消息赋予高优先级，使其在网络带宽有限的情况下优先得到传输。
- 0-RTT 快速重连： QUIC 连接断开时，能够以 0-RTT （Round Trip Time）的低时延快速重连。

参考资料

- <https://www.emqx.com/zh/blog/mqtt-over-quic>

## Server

- EMQX
- NanoMQ

## 参考资料

- <https://mcxiaoke.gitbooks.io/mqtt-cn/content/mqtt/01-Introduction.html>

- <https://github.com/mcxiaoke/mqtt>