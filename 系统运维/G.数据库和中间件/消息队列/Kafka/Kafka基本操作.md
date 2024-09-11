### 主题列表

要获取 `Kafka` 服务器中的主题列表，可以使用以下命令

语法

```bash
bin/kafka-topics.sh --list --bootstrap-server localhost:9092
```

输出

```bash
Hello-Kafka
```

如果创建多个主题，将在输出中获取主题名称

### 创建主题

```bash
bin/kafka-topics.sh \
  --bootstrap-server localhost:9092 \
  --topic first_topic \
  --create --partitions 3 \
  --replication-factor 1
```

### 启动生产者以发送消息

**语法**

```bash
bin/kafka-console-producer.sh --broker-list localhost:9092 --topic topic-name
```

从上面的语法，生产者命令行客户端需要两个主要参数 -

**代理列表** - 我们要发送邮件的代理列表。 在这种情况下，我们只有一个代理。 `Config / server.properties` 文件包含代理端口 ID，因为我们知道我们的代理正在侦听端口 9092，因此您可以直接指定它。

主题名称 - 以下是主题名称的示例。

**示例**

```bash
bin/kafka-console-producer.sh --broker-list localhost:9092 --topic Hello-Kafka
```

生产者将等待来自 `stdin` 的输入并发布到 `Kafka` 集群。 默认情况下，每个新行都作为新消息发布，然后在` config / producer.properties` 文件中指定默认生产者属性。 现在，您可以在终端中键入几行消息，如下所示。

**输出**

```bash
$ bin/kafka-console-producer.sh --broker-list localhost:9092 
--topic Hello-Kafka[2016-01-16 13:50:45,931] 
WARN property topic is not valid (kafka.utils.Verifia-bleProperties)
Hello
My first message
My second message
```

### 启动消费者以接收消息

与生产者类似，在`config / consumer.proper-ties` 文件中指定了缺省使用者属性。 打开一个新终端并键入以下消息消息语法。

**语法**

```bash
bin/kafka-console-consumer.sh \
  --bootstrap-server localhost:9092 \
  —-topic topic-name \
  --from-beginning
```

**示例**

```bash
bin/kafka-console-consumer.sh \
  --bootstrap-server localhost:9092 \
  —-topic Hello-Kafka \
  --from-beginning
```

**输出**

```bash
Hello
My first message
My second message
```

最后，您可以从制作商的终端输入消息，并看到他们出现在消费者的终端。 到目前为止，您对具有单个代理的单节点群集有非常好的了解。 现在让我们继续讨论多个代理配置