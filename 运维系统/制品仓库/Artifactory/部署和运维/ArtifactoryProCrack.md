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
import org.jfrog.license.api.a;

public class ArtifactoryLicenseVerifier {
  private static a d = new a();
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

两个 catch 都是 LicenseException，都是用于解密 License 的方法跟踪

```java
static {
      e = (new org.jfrog.license.a.a(new long[] { 
            -1726407428987257173L, 6552458022020060971L, 3287153214475526744L, 5042586162283887812L, -4384052826299009888L, -8316247795336524823L, 7936918235199102723L, -9094663790947624493L, 9088475072648118389L, 1469396353234180400L, 
            -4975391386710892121L, 2883662529518593947L, -6644985668287240272L, -1043285861329918989L, -817625965543746638L, -4327427692424278420L, -4202974542575490746L, 4084913491776174254L, -4282256311575388251L, 6990887362918677613L, 
            -4671518382712106854L, -3347688174536962261L, -8364399155899862521L, 7898951919847517800L, 8839912199487470757L, 3031818025859324673L, 106853704808426195L, -3611778508526093121L, -8105737370900856918L, 6130352475644159035L, 
            -4201706043959049251L, 53784998035928088L, -2947369105824247045L, 8521414782159216579L, -7311190625878140082L, -669692917166601870L, -4881555862245372125L, 2926336810353508206L, -3257019571948582356L, -2166269812610071076L, 
            -2406538007288339996L, 2332701653154828017L, -774681389005242811L, 7608268021729870750L, -1401899714320019095L, 2864339968838092845L, 4687655701271014568L, 8608138132958939213L, -2469333730728440366L, -8904286179561882499L })).toString();
}
```

因此会命中方法签名为

```java
  public License a(String paramString, String... paramVarArgs) throws LicenseException {
    for (String str : paramVarArgs) {
      try {
        return c(paramString, str);
      } catch (LicenseException licenseException) {}
    } 
    throw new LicenseException("License is invalid");
  }
```

这里会依次执行 c 方法，跟踪 c 方法

```java
  private License c(String paramString1, String paramString2) throws LicenseException {
    try {
      return a(paramString1, paramString2);
    } catch (LicenseException licenseException) {
      if (FipsMode.isFipsModeEnabled())
        throw licenseException; 
      return b(paramString1, paramString2);
    } 
  }
```

再跟踪 `a` 的签名

```java
  License a(String paramString1, String paramString2) throws LicenseException {
    License license = (new org.jfrog.license.multiplatform.a()).a(paramString1, e(paramString2));
    HashMap<Object, Object> hashMap = new HashMap<>();
    for (Map.Entry entry : license.getProducts().entrySet())
      hashMap.put(entry.getKey(), ((SignedProduct)entry.getValue()).parseProduct()); 
    License license1 = new License();
    license1.setValidateOnline(license.getValidateOnline());
    license1.setProducts((Map)hashMap);
    license1.setVersion(license.getVersion());
    return license1;
  }

  private PublicKey e(String paramString) throws LicenseException {
    try {
      X509EncodedKeySpec x509EncodedKeySpec = new X509EncodedKeySpec(Base64.decodeBase64(paramString.getBytes("UTF-8")));
      KeyFactory keyFactory = KeyFactory.getInstance("RSA", BCProviderFactory.getProvider());
      return keyFactory.generatePublic(x509EncodedKeySpec);
    } catch (Exception exception) {
      throw new LicenseException("Invalid public key", exception);
    } 
  }
  
```

第一行调用 `org.jfrog.license.multiplatform.a#a` 来生成一个 License 对象，那么这个应该是真正的解密 License 的地方

这个方法接受两个参数，一个是 String，另一个是 PublicKey，那么可以很自然的推测出 `e(paramString2)` 是用来从 `paramString2 即 c` 生成公钥对象用的

对 `c` 进行解密发现是一串 `Base64`，根据方法 `e` 可以判断出这个公钥是 `RSA` 格式的

