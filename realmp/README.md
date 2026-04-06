# realmp = realm + mptcp

## Deployment

拓扑参考如下

```mermaid
graph LR
    CLIENT --> IN
    IN == MPTCP ==> IX
    IX --> OUT
```

### 确认在`IN`和`IX`上mptcp已经启用

kernel参数应该与下面一致

```bash
$ sysctl -a | grep '^net\.mptcp\.'

net.mptcp.add_addr_timeout = 120
net.mptcp.allow_join_initial_addr_port = 1
net.mptcp.checksum_enabled = 0
net.mptcp.enabled = 1
net.mptcp.pm_type = 0
net.mptcp.stale_loss_cnt = 4
```

### 确认在`IN`和`IX`上`docker`和`docker compose`均已安装

版本过低不保证可用性

```bash
$ docker version
Server: Docker Engine - Community
 Engine:
  Version:          29.3.1
  API version:      1.54 (minimum version 1.40)
  Go version:       go1.25.8
  Git commit:       f78c987
  Built:            Wed Mar 25 16:13:48 2026
  OS/Arch:          linux/amd64
  Experimental:     false
 containerd:
  Version:          v2.2.2
  GitCommit:        301b2dac98f15c27117da5c8af12118a041a31d9
 runc:
  Version:          1.3.4
  GitCommit:        v1.3.4-0-gd6d73eb8
 docker-init:
  Version:          0.19.0
  GitCommit:        de40ad0
```

```bash
$ docker compose version
Docker Compose version v5.1.1
```

### 在`IN`上部署`ingress`

`mkdir -p /etc/realmp`

参考`ingress.toml`准备配置文件，存放于`/etc/realmp/ingress.toml`

`mkdir -p ~/realmp`

复制`realmp-ingress.yml`至`~/realmp/`

**这里注意，按照你自己的需求，修改文件中的`ports`代表的预映射端口**

```bash
docker compose -f realmp-ingress.yml up -d
```

### 在`IX`上部署`egress`

`mkdir -p /etc/realmp`

参考`egress.toml`准备配置文件，存放于`/etc/realmp/egress.toml`

复制`realmp-egress.yml`至`~/realmp/`

```bash
docker compose -f realmp-egress.yml up -d
```
