## dex-storage

安全起见，dexserver 签发的 id_token 有效期通常不会太长，这就需要 dexclient 凭借 Token 中的 refresh_token 隔段时间重新换取新的 Token，并通过某种机制将新 Token 中的 id_token 重新发回浏览器端保存

以 refresh_token 重新换取新的 Token，dex 需要持久化保存数据来执行各种各样的任务例如 track refresh tokens、preventing replays、and rotating keys

dexserver 在运行时跟踪 refresh_token、auth_code、keys、password 等，还要存储 connectors、认证请求等信息，因此需要将这些状态保存下来

并且 storage 也提供了对存储数据增删改查的接口

dex 提供了多种存储方案，如 

- etcd
- CRDs
- SQLite3
- Postgres
- MySQL
- memory

dexserver 会根据项目情况配置一个合适的 Storage，用以安全可靠地保存 refresh_token、auth_code、keys、password 等的状态，要考虑这个 Storage 实现方案的性能、稳定性、高可用性等多个因素

storage 段的配置的是 dexserver 的配置文件中进行存设置

源码：<https://github.com/dexidp/dex/blob/v2.35.3/storage/storage.go#L358-L372>

```go
// Connector is an object that contains the metadata about connectors used to login to Dex.
type Connector struct {
	// ID that will uniquely identify the connector object.
	ID string `json:"id"`
	// The Type of the connector. E.g. 'oidc' or 'ldap'
	Type string `json:"type"`
	// The Name of the connector that is used when displaying it to the end user.
	Name string `json:"name"`
	// ResourceVersion is the static versioning used to keep track of dynamic configuration
	// changes to the connector object made by the API calls.
	ResourceVersion string `json:"resourceVersion"`
	// Config holds all the configuration information specific to the connector type. Since there
	// no generic struct we can use for this purpose, it is stored as a byte stream.
	//
	// NOTE: This is a bug. The JSON tag should be `config`.
	// However, fixing this requires migrating Kubernetes objects for all previously created connectors,
	// or making Dex reading both tags and act accordingly.
	Config []byte `json:"email"`
}
```

源码：