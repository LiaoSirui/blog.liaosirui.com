定位 `ArtifactoryLicenseVerifier`

```bash
2025-07-31T01:45:26.561Z [jfrt ] [ERROR] [6b86db0550f78d99] [ArtifactoryLicenseVerifier:122] [http-nio-8081-exec-7] - Failed to decrypt license: last block incomplete in decryption
```

jdgui 打开 `artifactory-addons-manager-*.jar` （基于前人经验）搜索这个类 <https://github.com/java-decompiler/jd-gui/releases>

```
# 当前版本
export INST_AR_VERSION=7.117.9

# 容器中的目录
/opt/jfrog/artifactory/app/artifactory/tomcat/webapps/artifactory/WEB-INF/lib/artifactory-addons-manager-${INST_AR_VERSION}.jar
```

`org.artifactory.addon.ArtifactoryLicenseVerifier`

文件内只有一处调用 `Logger#error`，直接锁定目标方法是 `ArtifactoryLicenseVerifier#a(Ljava/lang/String)Lorg.jfrog.license.api.License`

```java
package org.artifactory.addon;

import org.jfrog.license.api.License;

public class ArtifactoryLicenseVerifier {
  // ..
  private static License a(String paramString) {
    try {
      return d.a(paramString);
    } catch (LicenseException licenseException) {
      a.error(licenseException.getMessage());
      b.debug(licenseException.getMessage(), (Throwable)licenseException);
      return null;
    } 
  }
  // ..
}
```

找到

```java
import org.jfrog.license.api.a;
```

查看 `org.jfrog.license.api.a#a(Ljava/lang/String)Lorg.jfrog.license.api.License`

```java
  public License a(String paramString) throws LicenseException {
    try {
      return a(paramString, e);
    } catch (LicenseException licenseException) {
      b.debug("Failed to load JFrog license");
      if (FipsMode.isFipsModeEnabled())
        return a(paramString, licenseException); 
      try {
        return b(paramString, d);
      } catch (LicenseException licenseException1) {
        b.debug("Failed to load legacy license");
        return a(paramString, licenseException1);
      } 
    } 
  }
```

跟踪 b

```java
import org.jfrog.license.legacy.b;
```

