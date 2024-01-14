FROM docker.io/squidfunk/mkdocs-material:9.5.3

# docs
COPY . /app/docs/blog.liaosirui.com
RUN \
    rm -rf /app/docs/blog.liaosirui.com/.assets \
    && rm -rf /app/docs/blog.liaosirui.com/README.md

# index
COPY .assets /app/docs/.assets
COPY README.md /app/docs/index.md

# config
COPY mkdocs.yml /app

WORKDIR /app
