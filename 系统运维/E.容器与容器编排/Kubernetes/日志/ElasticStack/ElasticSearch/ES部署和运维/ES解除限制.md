## 源码

选用分支 8.16.1

- <https://github.com/elastic/elasticsearch/tree/v8.16.1>

- <https://github.com/elastic/elasticsearch/releases/tag/v8.16.1>

## ES8 破解

修改 `LicenseVerifier.java`

<https://github.com/elastic/elasticsearch/blob/v8.16.1/x-pack/plugin/core/src/main/java/org/elasticsearch/license/LicenseVerifier.java>

```java
public static boolean verifyLicense(final License license, PublicKey publicKey) {
    return true;
}
```

修改 `XPackBuild.java`

<https://github.com/elastic/elasticsearch/blob/v8.16.1/x-pack/plugin/core/src/main/java/org/elasticsearch/xpack/core/XPackBuild.java>

```java
public class XPackBuild {

    public static final XPackBuild CURRENT;

    static {
        final String shortHash;
        final String date;

        Path path = getElasticsearchCodebase();
        if (false) {
            try (JarInputStream jar = new JarInputStream(Files.newInputStream(path))) {
                Manifest manifest = jar.getManifest();
                shortHash = manifest.getMainAttributes().getValue("Change");
                date = manifest.getMainAttributes().getValue("Build-Date");
            } catch (IOException e) {
                throw new RuntimeException(e);
            }
        } else {
            // not running from a jar (unit tests, IDE)
            shortHash = "Unknown";
            date = "Unknown";
        }

        CURRENT = new XPackBuild(shortHash, date);
    }
}
```

重新生成 class 文件

```bash
javac -cp "/usr/share/elasticsearch/lib/*:/usr/share/elasticsearch/modules/x-pack-core/*" LicenseVerifier.java
javac -cp "/usr/share/elasticsearch/lib/*:/usr/share/elasticsearch/modules/x-pack-core/*" XPackBuild.java
```

替换原始 x-pack-core 文件，此处需要解包 jar 文件并在替换后重新打包，细节见代码

```bash
version=8.16.1

unzip "/usr/share/elasticsearch/modules/x-pack-core/x-pack-core-${version}.jar" -d "./x-pack-core-${version}" \
    && cp LicenseVerifier.class "./x-pack-core-${version}/org/elasticsearch/license/" \
    && cp XPackBuild.class "./x-pack-core-${version}/org/elasticsearch/xpack/core/" 

jar -cvf "x-pack-core-${version}.jar" -C "x-pack-core-${version}/" .
```

完整的 Dockerfile

```dockerfile
# syntax=harbor.alpha-quant.tech/3rd_party/docker.io/docker/dockerfile:1.5.2

FROM harbor.alpha-quant.tech/3rd_party/docker.io/library/elasticsearch:8.16.1 as base

FROM harbor.alpha-quant.tech/3rd_party/docker.io/library/openjdk:23-jdk-bookworm as build

COPY --from=base /usr/share/elasticsearch/lib /usr/share/elasticsearch/lib
COPY --from=base /usr/share/elasticsearch/modules/x-pack-core /usr/share/elasticsearch/modules/x-pack-core

COPY libs/elasticsearch/x-pack/plugin/core/src/main/java/org/elasticsearch/license/LicenseVerifier.java /crack/LicenseVerifier.java
COPY libs/elasticsearch/x-pack/plugin/core/src/main/java/org/elasticsearch/xpack/core/XPackBuild.java /crack/XPackBuild.java

WORKDIR /crack

ARG version=8.16.1

RUN \
    true \
    \
    # Build calss file
    && javac -cp "/usr/share/elasticsearch/lib/*:/usr/share/elasticsearch/modules/x-pack-core/*" LicenseVerifier.java \
    && javac -cp "/usr/share/elasticsearch/lib/*:/usr/share/elasticsearch/modules/x-pack-core/*" XPackBuild.java \
    \
    # Build jar file
    && unzip "/usr/share/elasticsearch/modules/x-pack-core/x-pack-core-${version}.jar" -d "./x-pack-core-${version}" \
    && cp LicenseVerifier.class "./x-pack-core-${version}/org/elasticsearch/license/" \
    && cp XPackBuild.class "./x-pack-core-${version}/org/elasticsearch/xpack/core/" \
    \
    && jar -cvf "x-pack-core-${version}.jar" -C "x-pack-core-${version}/" . \
    \
    && true

FROM harbor.alpha-quant.tech/3rd_party/docker.io/library/elasticsearch:8.16.1

ARG version=8.16.1

COPY --from=build \
    "/crack/x-pack-core-${version}.jar" \
    "/usr/share/elasticsearch/modules/x-pack-core/x-pack-core-${version}.jar"

```

测试的 license

## 参考资料

- <https://blog.csdn.net/snake2u/article/details/123368146>