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

源码：<https://github.com/dexidp/dex/blob/v2.35.3/storage/sql/crud.go#L765-L783>

```go
func (c *conn) CreateConnector(connector storage.Connector) error {
	_, err := c.Exec(`
		insert into connector (
			id, type, name, resource_version, config
		)
		values (
			$1, $2, $3, $4, $5
		);
	`,
		connector.ID, connector.Type, connector.Name, connector.ResourceVersion, connector.Config,
	)
	if err != nil {
		if c.alreadyExistsCheck(err) {
			return storage.ErrAlreadyExists
		}
		return fmt.Errorf("insert connector: %v", err)
	}
	return nil
}
```

源码：<https://github.com/dexidp/dex/blob/v2.35.3/storage/kubernetes/storage.go#L259-L261>

```go
const (
	resourceAuthCode        = "authcodes"
	resourceAuthRequest     = "authrequests"
	resourceClient          = "oauth2clients"
	resourceRefreshToken    = "refreshtokens"
	resourceKeys            = "signingkeies" // Kubernetes attempts to pluralize.
	resourcePassword        = "passwords"
	resourceOfflineSessions = "offlinesessionses" // Again attempts to pluralize.
	resourceConnector       = "connectors"
	resourceDeviceRequest   = "devicerequests"
	resourceDeviceToken     = "devicetokens"
)

func (cli *client) CreateConnector(c storage.Connector) error {
	return cli.post(resourceConnector, cli.fromStorageConnector(c))
}
```

并且 dex-storage 存储 connectors 等数据之外，还有存储认证请求的接口，也就是 dex-server 每向后端认证一次，该认证请求会备份到 dex-storage 中

后端在认证成功后会返回 IDtoken，并存储在 dex-storage 中，其中包含了用户的信息

源码：<https://github.com/dexidp/dex/blob/v2.35.3/storage/storage.go#L175-L184>

```go
// Claims represents the ID Token claims supported by the server.
type Claims struct {
	UserID            string
	Username          string
	PreferredUsername string
	Email             string
	EmailVerified     bool

	Groups []string
}
```

## dex-server

在 dex 服务端配置允许登录的 dex 客户端：`staticClients` 段配置的是该 `dexserver` 允许接入的 `dexclient`（第三方应用） 信息，这个要跟 `dexclient` 那边的配置一致

在 dex-server 的配置文件中会设置 dex 存储链接方式和 connector 选项

```yaml
issuer: http://127.0.0.1:5556/dex
storage:
  type: sqlite3
  config:
    file: examples/dex.db
web:
  http: 0.0.0.0:5556

connectors:
  - type: ldap
    name: OpenLDAP
    id: ldap
    config:
      host: localhost:389
      insecureNoSSL: true
      bindDN: cn=admin,dc=example,dc=org
      bindPW: admin
      usernamePrompt: Email Address
      userSearch:
        baseDN: ou=People,dc=example,dc=org
        filter: "(objectClass=person)"
        username: mail
        idAttr: DN
        emailAttr: mail
        nameAttr: cn
      groupSearch:
        baseDN: ou=Groups,dc=example,dc=org
        filter: "(objectClass=groupOfNames)"
        userMatchers:
          - userAttr: DN
            groupAttr: member
        nameAttr: cn

staticClients:
  - id: example-app
    redirectURIs:
      - "http://127.0.0.1:5555/callback"
    name: "Example App"
    secret: ZXhhbXBsZS1hcHAtc2Vjcm

```

dex-server认证流程:

（1）解析 oauth2-client 发来的 http 请求，解析为 AuthRequest 结构体

（2）把 AuthRequest 请求备份到 dex-storage

（3）根据请求中的 connector_id，找出 dex-storage 中的该 connector 的具体信息。检索 dex-storage 存储中的连接器对象。 该列表包括 ConfigMap 中定义的静态连接器和从存储中检索的动态连接器

（4）根据 connector 的信息进行登录认证

源码：<https://github.com/dexidp/dex/blob/v2.35.3/server/handlers.go#L128-L187>

```go
// handleAuthorization handles the OAuth2 auth endpoint.
func (s *Server) handleAuthorization(w http.ResponseWriter, r *http.Request) {
	// Extract the arguments
	if err := r.ParseForm(); err != nil {
		s.logger.Errorf("Failed to parse arguments: %v", err)

		s.renderError(r, w, http.StatusBadRequest, err.Error())
		return
	}

	connectorID := r.Form.Get("connector_id")

	connectors, err := s.storage.ListConnectors()
	if err != nil {
		s.logger.Errorf("Failed to get list of connectors: %v", err)
		s.renderError(r, w, http.StatusInternalServerError, "Failed to retrieve connector list.")
		return
	}

	// We don't need connector_id any more
	r.Form.Del("connector_id")

	// Construct a URL with all of the arguments in its query
	connURL := url.URL{
		RawQuery: r.Form.Encode(),
	}

	// Redirect if a client chooses a specific connector_id
	if connectorID != "" {
		for _, c := range connectors {
			if c.ID == connectorID {
				connURL.Path = s.absPath("/auth", url.PathEscape(c.ID))
				http.Redirect(w, r, connURL.String(), http.StatusFound)
				return
			}
		}
		s.renderError(r, w, http.StatusBadRequest, "Connector ID does not match a valid Connector")
		return
	}

	if len(connectors) == 1 && !s.alwaysShowLogin {
		connURL.Path = s.absPath("/auth", url.PathEscape(connectors[0].ID))
		http.Redirect(w, r, connURL.String(), http.StatusFound)
	}

	connectorInfos := make([]connectorInfo, len(connectors))
	for index, conn := range connectors {
		connURL.Path = s.absPath("/auth", url.PathEscape(conn.ID))
		connectorInfos[index] = connectorInfo{
			ID:   conn.ID,
			Name: conn.Name,
			Type: conn.Type,
			URL:  template.URL(connURL.String()),
		}
	}

	if err := s.templates.login(r, w, connectorInfos); err != nil {
		s.logger.Errorf("Server template error: %v", err)
	}
}
```

## dex-client

dex-client 首先是根据一系列参数构造出 `oidc.Provider` 及 `oidc.IDTokenVerifier`，后面获取认证系统的跳转地址、获取 id_token、校验 id_token 都会用到

第三方应用需要编写 dex-client 端的代码需要和 dex-server 进行交互，流程为

（1）服务端配置 dex-client 的信息，只有该 dex-client 信息已经在 dex-server 中配置，相应的 dex-client 才能进行交互

```yaml
staticClients:
  - id: example-app
    redirectURIs:
      - "http://127.0.0.1:5555/callback"
    name: "Example App"
    secret: ZXhhbXBsZS1hcHAtc2Vjcm

```

（2）用 dex-server 端配置的 issuer URL，在第三方应用（client-app）中初始化 OIDC 身份验证服务

```go
provider, err := oidc.NewProvider(ctx, issuerURL)
if err != nil {
	return fmt.Errorf("failed to query provider %q: %v", issuerURL, err)
}
```

（3）配置 OAuth2 的客户端配置

```go
func (a *app) oauth2Config(scopes []string) *oauth2.Config {
	return &oauth2.Config{
		ClientID:     a.clientID,
		ClientSecret: a.clientSecret,
		Endpoint:     a.provider.Endpoint(),
		Scopes:       scopes,
		RedirectURL:  a.redirectURI,
	}
}
```

示例：

```go
// Configure the OAuth2 config with the client values.
oauth2Config := oauth2.Config{
    // client_id and client_secret of the client.
    ClientID:     "example-app",
    ClientSecret: "example-app-secret",

    // The redirectURL.
    RedirectURL: "http://127.0.0.1:5555/callback",

    // Discovery returns the OAuth2 endpoints.
    Endpoint: provider.Endpoint(),

    // "openid" is a required scope for OpenID Connect flows.
    //
    // Other scopes, such as "groups" can be requested.
    Scopes: []string{oidc.ScopeOpenID, "profile", "email", "groups"},
}

```

（4）创建 ID token 的解析器

```go
// Create an ID token parser.
idTokenVerifier := provider.Verifier(&oidc.Config{ClientID: "example-app"})

```

（5）然后，客户端发送 http 请求，请求中包含（client_id 、CA、connector_id 等）HTTP 服务器应将未经身份验证的用户重定向到 dex，dex 服务端验证 dex-client 后开始处理用户登录认证

````go
```
The HTTP server should then redirect unauthenticated users to dex to initialize the OAuth2 flow.
```
// handleRedirect is used to start an OAuth2 flow with the dex server.
func handleRedirect(w http.ResponseWriter, r *http.Request) {
    state := newState()
    http.Redirect(w, r, oauth2Config.AuthCodeURL(state), http.StatusFound)
}

````

（7）dex 验证用户的身份后，它将使用可以交换 ID 令牌的代码将用户重定向回客户端应用程序。 然后，可以通过上面创建的验证程序来解析 ID 令牌

```go
func handleOAuth2Callback(w http.ResponseWriter, r *http.Request) {
    state := r.URL.Query().Get("state")

    // Verify state.

    oauth2Token, err := oauth2Config.Exchange(ctx, r.URL.Query().Get("code"))
    if err != nil {
        // handle error
    }

    // Extract the ID Token from OAuth2 token.
    rawIDToken, ok := oauth2Token.Extra("id_token").(string)
    if !ok {
        // handle missing token
    }

    // Parse and verify ID Token payload.
    idToken, err := idTokenVerifier.Verify(ctx, rawIDToken)
    if err != nil {
        // handle error
    }

    // Extract custom claims.
    var claims struct {
        Email    string   `json:"email"`
        Verified bool     `json:"email_verified"`
        Groups   []string `json:"groups"`
    }
    if err := idToken.Claims(&claims); err != nil {
        // handle error
    }
}

```

## connector

dex-server 端 connector 的信息，存储在 static 静态文件和动态的 dex-storage 中

决定了 dex-server 对接的 OIDC 的认证方案的配置
