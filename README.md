> 一个用于构建与快速启动多种服务的 Docker 镜像集合 / Docker Compose 集合

[![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](https://www.apache.org/licenses/LICENSE-2.0)
[![Build Status](https://img.shields.io/badge/build-passing-brightgreen.svg)]()

本项目包含多个服务（如 `PHP`, `MySQL`, `Redis`, `Nginx` 等）的 `Dockerfile` 与 `docker compose` 配置，方便统一构建、部署和本地开发使用。

# QQ交流群: 544315207

## 📦 特性 / 支持服务

- 多种服务组合：PHP + Nginx + MySQL + Redis + Elasticsearch + MongoDB + RabbitMQ + …（参见根目录各服务子目录）
- 支持快速一键构建与启动所有服务
- 支持按需单独构建 / 单独启动某个服务
- 统一的 sample 配置模板，包含 `.env` 与 `compose.sample.yml`，方便根据环境变量定制配置

## 🚀 快速开始
1. clone 项目
    ```shell
    git clone https://github.com/xiaoyu98628/docker.git
    # 或者
    git clone https://gitee.com/xiaoyu98628/docker.git
   ```
2. 进入项目根目录，复制并改名 `compose.yml` 和 `.env`
    ```shell
    cd docker
    cp ./compose.sample.yml ./compose.yml
    cp ./sample.env ./.env
   ```
3. 复制并改名对应镜像的 `compose.yml` 和 `.env`
    ```shell
    cp ./镜像名/版本号/compose.sample.yml ./镜像名/版本号/compose.yml
    cp ./镜像名/版本号/sample.env ./镜像名/版本号/.env
    # 例如
    cp ./php/8.2/compose.sample.yml ./php/8.2/compose.yml
    cp ./php/8.2/sample.env ./php/8.2/.env
    ```
4. 在根目录引入你想使用的镜像的 compose.yml
    ```yaml
    # 例如
    include :
      - php/8.2/compose.yml
   # ... 其余不变
    ```
5. 启动服务
    ```shell
    # 批量启动
    docker compose up -d [镜像名]
    # 例如
    docker compose up -d
    docker compose up -d php82
   
    #  单独构建
    docker compose build --no-cache [镜像名]
    # 例如
    docker compose build --no-cache
    docker compose build --no-cache php82
   
    # 查看运行日志
    docker compose logs -f [镜像名]
    # 例如
    docker compose logs -f
    docker compose logs -f php82
   
    # 停止并移除服务
    docker compose down [镜像名]
    # 例如
    docker compose down
    docker compose down php82
   ```

## 📦 镜像列表
| 服务名           | 版本                    | 说明                                   |
|---------------|-----------------------|--------------------------------------|
| Elasticsearch | 8.4.0 / 9.1.2         | [README.md](elasticsearch/README.md) |
| Etcd          | 3.5.9                 |                                      |
| Jenkins       | 2.4.14                |                                      |
| Kibana        | 8.4.0 / 9.1.2         | [README.md](kibana/README.md)        |
| MongoDB       | 6.0                   | [README.md](mongo/README.md)         |
| Mongo-Express | 6.0                   | [README.md](mongo/README.md)         |
| MySQL         | 8 / 9                 | [README.md](mysql/README.md)         |
| Nginx         | 1.21 / 1.28           | [README.md](nginx/README.md)         |
| PHP           | 8.2 / 8.3 / 8.4 / 8.5 | [README.md](php/README.md)           |
| RabbitMQ      | 3.11                  | [README.md](rabbitmq/README.md)      |
| Redis         | 6 / 7 / 8             | [README.md](redis/README.md)         |

## 🔧 配置说明
- **sample.env / 各服务目录下的 sample.env**：环境变量模板，请根据需要修改后改名为 .env
- **compose.sample.yml / 各服务目录下的 compose.sample.yml**：`docker compose` 模板，改名为 compose.yml 后即可使用
- 各服务镜像使用独立子目录管理，便于版本控制与组合配置

## 📚 推荐用途
- 本地开发环境搭建 — 适合同时启动多服务（Web + DB + 缓存/消息队列等）的复杂系统
- 多项目隔离 — 不同项目可选不同服务组合
- 快速试验 / 调试 / PoC／原型开发

## ✅ 已知注意事项 & 推荐实践
- 本项目镜像通常基于轻量基础镜像（如 Alpine / 官方 PHP‑FPM），构建时遵循 Dockerfile 最佳实践，例如避免 root 运行、减少层数、合理缓存构建依赖等。
- 如果你以后用于生产部署，建议对 compose / Dockerfile 做必要安全性与性能优化，例如只运行必要服务、做权限降级、为持久化数据挂载 volume 等。
- 推荐对 .env / 配置文件加入 .gitignore，避免将敏感配置写入版本控制

## 🤝 贡献指南
1. 在根目录创建一个子目录，命名为 **<服务名>/<版本>**
2. 在子目录中添加 Dockerfile（如果需要构建镜像） + compose.sample.yml + sample.env
3. 更新 README，描述新服务用途与注意事项
4. 提交 PR／Push 即可

## 🙏 致谢
站在巨人的肩膀上。我们衷心感谢以下项目：
* 搭建参考 **yeszao/dnmp** 仓库：<a href="https://github.com/yeszao/dnmp" target="_blank"> https://github.com/yeszao/dnmp </a>
* 感谢 **docker-php-extension-installer** 快速安装PHP扩展脚本：<a href="https://github.com/mlocati/docker-php-extension-installer" target="_blank"> https://github.com/mlocati/docker-php-extension-installer </a>
* 感谢 **acme.sh** 实现ACME客户端协议的纯Unix shell脚本：<a href="https://github.com/acmesh-official/acme.sh" target="_blank"> https://github.com/acmesh-official/acme.sh </a>
* 感谢 **docker-nginx** 容器自动申请ssl证书脚本：<a href="https://github.com/xiaojun207/docker-nginx" target="_blank"> https://github.com/xiaojun207/docker-nginx </a>

## 📝 License
[Apache-2.0](https://github.com/xiaoyu98628/docker/blob/main/LICENSE)

[![Star History Chart](https://api.star-history.com/svg?repos=xiaoyu98628/docker&type=Date)](https://star-history.com/#xiaoyu98628/docker&Date)
