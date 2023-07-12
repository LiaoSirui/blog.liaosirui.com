## Distroless 简介

Distroless Docker Images是谷歌为了帮助构建更轻薄的容器而提出的一个项目

GitHub 地址：<https://github.com/GoogleContainerTools/distroless>

| Image                                | Tags                                  |
| ------------------------------------ | ------------------------------------- |
| gcr.io/distroless/static-debian11    | latest, nonroot, debug, debug-nonroot |
| gcr.io/distroless/base-debian11      | latest, nonroot, debug, debug-nonroot |
| gcr.io/distroless/cc-debian11        | latest, nonroot, debug, debug-nonroot |
| gcr.io/distroless/python3-debian11   | latest, nonroot, debug, debug-nonroot |
| gcr.io/distroless/java-base-debian11 | latest, nonroot, debug, debug-nonroot |
| gcr.io/distroless/java11-debian11    | latest, nonroot, debug, debug-nonroot |
| gcr.io/distroless/java17-debian11    | latest, nonroot, debug, debug-nonroot |
| gcr.io/distroless/nodejs14-debian11  | latest, nonroot, debug, debug-nonroot |
| gcr.io/distroless/nodejs16-debian11  | latest, nonroot, debug, debug-nonroot |
| gcr.io/distroless/nodejs18-debian11  | latest, nonroot, debug, debug-nonroot |

## 打包 python

这是一个示例 api 服务器:

```python
import fastapi, uvicorn
from starlette.requests import Request
import prometheus_client
import os

api = fastapi.FastAPI()

REQUESTS = prometheus_client.Counter(
    'requests', 'Application Request Count',
    ['endpoint']
)

@api.get('/ping')
def index(request: Request):
    REQUESTS.labels(endpoint='/ping').inc()
    return "pong"

@api.get('/metrics')
def metrics():
    return fastapi.responses.PlainTextResponse(
        prometheus_client.generate_latest()
    )

if __name__ == "__main__":
    print("Starting webserver...")
    uvicorn.run(
        api, 
        host="0.0.0.0",
        port=int(os.getenv("PORT", 8080)),
        debug=os.getenv("DEBUG", False),
        log_level=os.getenv('LOG_LEVEL', "info"),
        proxy_headers=True
    )

```

将使用 Pipenv 作为包管理器。这是 Pipfile:

```toml
[[source]]
url = "https://pypi.org/simple"
verify_ssl = true
name = "pypi"

[packages]
fastapi = "==0.77.1"
uvicorn = "==0.17.6"
prometheus-client = "==0.14.1"
Jinja2 = "==3.1.2"

[dev-packages]

[requires]
python_version = "3.10"
```

以下 Dockerfile，将 FastAPI 应用程序与 distroless Python 映像打包在一起

```dockerfile
FROM python:3.10-slim AS base

# Setup env

## Avoid to write .pyc files on the import of source modules
ENV PYTHONDONTWRITEBYTECODE 1

# Enable fault handler
ENV PYTHONFAULTHANDLER 1

# Dependencies
FROM base AS python-deps

### Install pipenv and compilation dependencies
RUN pip install pipenv \
    && apt-get update \
    && apt-get install -y --no-install-recommends gcc

### Install python dependencies in /.venv
COPY Pipfile .
COPY Pipfile.lock .

# Allows to install the pipenv packages into the project instead of home user
# --deploy
RUN PIPENV_VENV_IN_PROJECT=1 pipenv install --deploy

# Runtime
FROM gcr.io/distroless/python3

WORKDIR /app

# Copy the python packages because the distroless base image does 
COPY --from=python-deps /.venv/lib/python3.10/site-packages /app/site-packages

# Set the Python path where the interpreter will look for the packages
ENV PYTHONPATH /app/site-packages
COPY . .

EXPOSE 8080
ENTRYPOINT ["python", "app.py"]

```

