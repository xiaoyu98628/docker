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

## 多证书配置

公共配置和 DNS API 凭据保存在 `acme/.env`。每张独立证书使用一份
`config/acme/domains/*.conf` 文件，例如：

```ini
# true 表示申请和续期；false 表示停止处理但保留已有证书。
enabled=true

# 主域名，同时用于生成 certs/<domain>/ 证书目录。
domain=example.com

# 签入同一张证书的附加域名，多个值使用分号分隔，可以留空。
alt_names=www.example.com;api.example.com

# webroot 或 dns；留空时使用 ACME_DEFAULT_MODE。
mode=webroot

# 仅在 dns 模式填写，例如 dns_cf、dns_ali。
dns_provider=
```

只有 `.conf` 文件会被读取。服务会按 `ACME_SYNC_INTERVAL_SECONDS` 定时扫描配置，
新增、修改或申请失败的证书都会自动处理，也可以立即重新启动 `acme` 服务：

```bash
docker compose up -d --build acme
docker compose logs -f acme
```

证书安装目录为：

```text
/usr/config/acme/certs/<domain>/
```

修改域名、验证模式、DNS Provider 或全局证书参数后，服务会重新签发证书。
如果安装目录中的证书文件丢失，但申请参数没有变化，服务只会从 acme.sh
重新安装已有证书，不会向 CA 强制申请新证书。
将 `enabled` 设为 `false` 或把文件改成非 `.conf` 后缀，会停止该证书的自动处理和续期，
但不会删除已经安装的证书和 acme.sh 内部数据。

续期成功后，acme 会更新 `/usr/config/acme/nginx.reload`，通知 Nginx 检查配置并热重载。

## 不推荐

拆分后不建议继续主推 `nginx` mode，因为它要求 acme 进程操作 Nginx 配置和 reload，耦合会重新变重。
