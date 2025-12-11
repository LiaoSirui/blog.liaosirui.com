参考：<https://dev.hsrn.nyu.edu/hsrn-projects/kubernetes-bare-metal/-/issues/7>

```yaml
--- FelixConfiguration/default
+++ FelixConfiguration/default
@@ -1,9 +1,10 @@
 apiVersion: crd.projectcalico.org/v1
 kind: FelixConfiguration
 metadata:
   name: default
 spec:
   bpfLogLevel: ""
+  featureDetectOverride: ChecksumOffloadBroken=true
   ipipEnabled: true
   logSeverityScreen: Info
   reportingInterval: 0s

```

