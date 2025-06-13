- Serdes（serializer 和 deserializer）

```java
The Kafka Protobuf serdes protocol. The payload's first byte is the serdes magic byte, the next 4-bytes are
the schema ID, the next variable-sized bytes are the message indexes, followed by the normal binary encoding of
the Protobuf data.
```

- Raw

```java
The raw Protobuf protocol. The full payload is the normal binary encoding of the Protobuf data.
```
