# xiaoyu98628/docker

[![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](https://www.apache.org/licenses/LICENSE-2.0) 
[![Build Status](https://img.shields.io/badge/build-passing-brightgreen.svg)]()

> 一个用于构建与快速启动多种服务的 Docker 镜像集合 / Docker-Compose 集合

本项目包含多个服务（如 `PHP`, `MySQL`, `Redis`, `Nginx` 等）的 `Dockerfile` 与 `docker-compose` 配置，方便统一构建、部署和本地开发使用。

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
    docker compose up -d
   
    #  单独构建
    docker compose build --no-cache [镜像名]
    # 例如
    docker compose build --no-cache php82
   
    # 单独启动
    docker compose up -d [镜像名]
    # 例如
    docker compose up -d php82
   
    # 查看运行日志
    docker-compose logs -f
   
    # 停止并移除服务
    docker-compose down
   ```

## 📦 镜像列表
| 服务名           | 版本                    | 说明 |
|---------------|-----------------------|----|
| Elasticsearch | 8.4.0 / 9.1.2         |    |
| etcd          | 3.5.9                 |    |
| jenkins       | 2.4.14                |    |
| kibana        | 8.4.0 / 9.1.2         |    |
| mongoDB       | 6.0                   |    |
| MySQL         | 8 / 9                 |    |
| Nginx         | 1.21 / 1.28           |    |
| PHP           | 8.2 / 8.3 / 8.4 / 8.5 |    |
| RabbitMQ      | 3.11                  |    |
| Redis         | 6 / 7 / 8             |    |

## 🔧 配置说明
- **sample.env / 各服务目录下的 sample.env**：环境变量模板，请根据需要修改后改名为 .env
- **compose.sample.yml / 各服务目录下的 compose.sample.yml**：docker-compose 模板，改名为 compose.yml 后即可使用
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

## 📝 License
[Apache-2.0](https://github.com/xiaoyu98628/docker/blob/main/LICENSE)
