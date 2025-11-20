项目地址：<https://github.com/kubernetes/git-sync>

运行容器进行测试

GitLab 项目 Token 需要授予至少 Developer 角色，并且勾选 read_repository 权限

```bash
export GITLAB_READONLY_TOKEN=glpat-...

docker run --rm \
    -v /tmp/git:/tmp/git \
    -u $(id -u):$(id -g) \
    -e GIT_SSL_NO_VERIFY="true" \
    -e GITSYNC_PERIOD=30s \
    -e GITSYNC_ROOT=/tmp/git/root \
    -e GITSYNC_REPO=https://gitlab.alpha-quant.tech/data-platform/airflow-dags.git \
    -e GITSYNC_REF=main \
    -e GITSYNC_USERNAME=oauth2 \
    -e GITSYNC_PASSWORD="${GITLAB_READONLY_TOKEN}" \
    harbor.alpha-quant.tech/3rd_party/registry.k8s.io/git-sync/git-sync:v4.5.0
```

