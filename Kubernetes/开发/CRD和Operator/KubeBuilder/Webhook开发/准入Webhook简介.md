## Webhook 简介

在 kubernetes 中有三种 Webhook: 准入 Webhook、授权 Webhook 和 CRD 转换 Webhook

授权 Webhook: <https://kubernetes.io/zh-cn/docs/reference/access-authn-authz/webhook/>

CRD 转换 Webhook：<https://kubernetes.io/zh-cn/docs/tasks/extend-kubernetes/custom-resources/custom-resource-definition-versioning/#webhook-conversion>

官方文档：<https://book.kubebuilder.io/cronjob-tutorial/running-webhook.html>

## 创建 Webhook

```bash
kubebuilder create webhook \
--group webapp \
--version v1 \
--kind Guestbook \
--defaulting \
--program
```

- `--defaulting` : 创建修改性质的 webhook
- `--programmatic-validation`: 创建验证性质的 webhook

会生成 `api/v1/guestbook_webhook.go`

### 实现 MutatingAdmissionWebhook

- `api/v1/guestbook_webhook.go`

修改 `spec.image` 的值为 `nginx.1.14.2`

```go
// Default implements webhook.Defaulter so a webhook will be registered for the type
func (r *Guestbook) Default() {
 guestbooklog.Info("default", "name", r.Name)

 // TODO(user): fill in your defaulting logic.
 if r.Spec.Image != "nginx:1.14.2" {
  r.Spec.Image = "nginx:1.14.2"
 }
}
```

### 实现 ValidatingAdmissionWebhook

- `api/v1/guestbook_webhook.go`

验证 `spec.name`，当值不为 guestbook-pod 则验证失败

```go
// ValidateCreate implements webhook.Validator so a webhook will be registered for the type
func (r *Guestbook) ValidateCreate() (admission.Warnings, error) {
 guestbooklog.Info("validate create", "name", r.Name)

 // TODO(user): fill in your validation logic upon object creation.
 if r.Spec.Name != "guestbook-pod" {
  return nil, errors.New("err spec name")
 }

 return nil, nil
}

// ValidateUpdate implements webhook.Validator so a webhook will be registered for the type
func (r *Guestbook) ValidateUpdate(old runtime.Object) (admission.Warnings, error) {
 guestbooklog.Info("validate update", "name", r.Name)

 // TODO(user): fill in your validation logic upon object update.
 if r.Spec.Name != "guestbook-pod" {
  return nil, errors.New("err spec name")
 }
 return nil, nil
}
```

