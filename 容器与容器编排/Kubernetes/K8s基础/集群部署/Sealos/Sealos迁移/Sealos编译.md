```bash
dnf install -y go git
dnf install -y --enablerepo=crb device-mapper-devel btrfs-progs-devel gpgme-devel

go env -w GO111MODULE=on
go env -w GOPROXY=https://goproxy.cn,direct

git clone https://github.com/labring/sealos.git -b v5.1.2
cd sealos/lifecycle || exit 1
CGO_ENABLED=1 GOOS=linux GO111MODULE=on \
    go build -o sealos ./cmd/sealos

```

