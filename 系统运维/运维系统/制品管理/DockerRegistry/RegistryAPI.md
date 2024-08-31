使用 docker 官方的封装的接口来操作镜像仓库，示例代码如下：

（1）列出镜像：

```go
package main

import (
	"context"
	"fmt"
	"io"
	"log"
	"net/http"
	"net/url"

	"github.com/docker/distribution/registry/client"
	"github.com/docker/distribution/registry/client/auth"
	"github.com/docker/distribution/registry/client/auth/challenge"
	"github.com/docker/distribution/registry/client/transport"
)

type regCredentialStore struct {
	Username      string
	Password      string
	RefreshTokens map[string]string
}

func (tcs *regCredentialStore) Basic(*url.URL) (string, string) {
	return tcs.Username, tcs.Password
}

func (tcs *regCredentialStore) RefreshToken(u *url.URL, service string) string {
	return tcs.RefreshTokens[service]
}

func (tcs *regCredentialStore) SetRefreshToken(u *url.URL, service string, token string) {
	if tcs.RefreshTokens != nil {
		tcs.RefreshTokens[service] = token
	}
}

func ping(manager challenge.Manager, endpoint, versionHeader string) ([]auth.APIVersion, error) {
	resp, err := http.Get(endpoint)
	if err != nil {
		return nil, err
	}
	defer resp.Body.Close()

	if err := manager.AddResponse(resp); err != nil {
		return nil, err
	}
	return auth.APIVersions(resp, versionHeader), err
}

func main() {

	var err error

	creds := &regCredentialStore{Username: "admin", Password: "password"}
	challengeManager := challenge.NewSimpleManager()

	_, err = ping(challengeManager, "http://10.24.9.99:8081/v2/", "")
	if err != nil {
		log.Fatal(err)
	}

	t := transport.NewTransport(
		nil,
		auth.NewAuthorizer(challengeManager, auth.NewBasicHandler(creds)),
	)
	registry, err := client.NewRegistry("http://10.24.9.99:8081", t)
	if err != nil {
		log.Fatal(err)
	}

	ctx := context.Background()
	allImages := make([]string, 0)
	var last string
	for {
		images := make([]string, 1024)
		registry.Repositories(ctx, images, last)

		count, err := registry.Repositories(ctx, images, last)
		if err == io.EOF {
			allImages = append(allImages, images[:count]...)
			break
		} else if err != nil {
			log.Fatal(err)
		}
		last = images[count-1]
		allImages = append(allImages, images...)
	}

	fmt.Println(allImages)

}

```

（2）列出 tag：

```bash

```

参考：

- <https://github.com/distribution/distribution/tree/main/registry/client>