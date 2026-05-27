# Acme

独立的 acme.sh 证书申请服务，用于把 SSL 证书申请和 Nginx 镜像解耦。

## 设计

- `nginx` 只负责 Web 服务和读取证书。
- `acme` 只负责申请、续期、安装证书。
- 证书统一写入 `/usr/config/acme/certs/<domain>/`。
- acme 账户数据写入 `/usr/config/acme/account/`。
- Webroot 校验文件写入 `/usr/share/nginx/html/.well-known/acme-challenge/`。

## 推荐模式

### Webroot

适合普通单域名或多域名证书。Nginx 保持运行，acme 容器写入 challenge 文件，由 Nginx 对外提供访问。

### DNS

适合泛域名证书，例如 `*.example.com`，或 80/443 端口不方便暴露的场景。

## 不推荐

拆分后不建议继续主推 `nginx` mode，因为它要求 acme 进程操作 Nginx 配置和 reload，耦合会重新变重。
