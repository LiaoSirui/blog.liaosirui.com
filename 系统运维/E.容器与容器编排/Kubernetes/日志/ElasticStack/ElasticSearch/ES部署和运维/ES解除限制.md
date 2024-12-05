## 源码

选用 eck-operator 2.15.0

- <https://github.com/elastic/cloud-on-k8s/tree/v2.15.0>
- <https://github.com/elastic/cloud-on-k8s/releases/tag/v2.15.0>

选用分支 8.16.1

- <https://github.com/elastic/elasticsearch/tree/v8.16.1>

- <https://github.com/elastic/elasticsearch/releases/tag/v8.16.1>

## ES8 解除限制

### eck-operator

eck-operator 解除限制

<https://github.com/elastic/cloud-on-k8s/blob/v2.15.0/pkgEnterpriseFeaturesEnabledcontroller/common/license/check.go#L92-L99>

修改为

```go
 func (lc *checker) EnterpriseFeaturesEnabled(ctx context.Context) (bool, error) {
-	license, err := lc.CurrentEnterpriseLicense(ctx)
-	if err != nil {
-		return false, err
-	}
-	return license != nil, nil
+	return true, nil
 }

```

<https://github.com/elastic/cloud-on-k8s/blob/v2.15.0/pkg/controller/common/license/check.go#L101-L120>

修改为

```go
// Valid returns true if the given Enterprise license is valid or an error if any.
 func (lc *checker) Valid(ctx context.Context, l EnterpriseLicense) (bool, error) {
-	pk, err := lc.publicKeyFor(l)
-	if err != nil {
-		return false, errors.Wrap(err, "while loading signature secret")
-	}
-	if len(pk) == 0 {
-		ulog.FromContext(ctx).Info("This is an unlicensed development build of ECK. License management and Enterprise features are disabled")
-		return false, nil
-	}
-	verifier, err := NewVerifier(pk)
-	if err != nil {
-		return false, err
-	}
-	status := verifier.Valid(ctx, l, time.Now())
-	if status == LicenseStatusValid {
-		return true, nil
-	}
-	return false, nil
+	return true, nil
 }

```

<https://github.com/elastic/cloud-on-k8s/blob/v2.15.0/pkg/controller/common/license/check.go#L122-L134>

修改为

```go
 // ValidOperatorLicenseKeyType returns true if the current operator license key is valid
 func (lc checker) ValidOperatorLicenseKeyType(ctx context.Context) (OperatorLicenseType, error) {
-	lic, err := lc.CurrentEnterpriseLicense(ctx)
-	if err != nil {
-		ulog.FromContext(ctx).V(-1).Info("Invalid Enterprise license, fallback to Basic: " + err.Error())
-	}
-
-	licType := lic.GetOperatorLicenseType()
-	if _, valid := OperatorLicenseTypeOrder[licType]; !valid {
-		return licType, fmt.Errorf("invalid license key: %s", licType)
-	}
-	return licType, nil
+	return LicenseTypeEnterprise, nil
 }

```

重新构建

```dockerfile
# syntax=harbor.alpha-quant.tech/3rd_party/docker.io/docker/dockerfile:1.5.2

FROM harbor.alpha-quant.tech/3rd_party/docker.io/library/golang:1.23.2-bookworm AS builder

ARG TARGETOS
ARG TARGETARCH
ARG TARGETVARIANT=""
ARG GOPROXY="http://nexus.alpha-quant.tech/repository/goproxy,direct"

ENV GOOS=${TARGETOS} GOARCH=${TARGETARCH} GOARM=${TARGETVARIANT} GOPROXY=${GOPROXY}

WORKDIR /go/src/github.com/elastic/cloud-on-k8s

COPY ./libs/cloud-on-k8s/Makefile \
    ./libs/cloud-on-k8s/go.mod \
    ./libs/cloud-on-k8s/go.sum \
    ./
RUN --mount=type=cache,mode=0755,target=/go/pkg/mod go mod download

COPY ./libs/cloud-on-k8s/config/eck.yaml .

# Copy the sources
COPY ./libs/cloud-on-k8s/pkg/ pkg/
COPY ./libs/cloud-on-k8s/cmd/ cmd/
COPY ./libs/cloud-on-k8s/cmd/license-initializer/testdata/test.key /license.key
COPY ./VERSION .

# Build
RUN --mount=type=cache,mode=0755,target=/go/pkg/mod \
    CGO_ENABLED=0 GOOS=linux LICENSE_PUBKEY=/license.key make go-build

FROM harbor.alpha-quant.tech/3rd_party/docker.elastic.co/eck/eck-operator:2.15.0

COPY --from=builder /go/src/github.com/elastic/cloud-on-k8s/elastic-operator .

```

### ElasticSearch

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

测试的 license，可从官方获取 Signature（version 版本为 v5）

<https://github.com/elastic/elasticsearch/blob/v8.16.1/x-pack/plugin/src/yamlRestTest/resources/rest-api-spec/test/license/30_enterprise_license.yml#L18>

## 参考资料

- <https://blog.csdn.net/snake2u/article/details/123368146>