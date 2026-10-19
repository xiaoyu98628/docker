# MariaDB 开发环境

提供独立的 `mariadb12` 服务，基于官方 `mariadb:12` 镜像，与现有 MySQL 服务使用各自的数据目录。当前官方 `12` 标签对应 12.3 LTS；该标签会随 12 系列更新，升级前应检查发布说明。

## 启动

在仓库根目录准备本地配置：

```sh
cp mariadb/12/compose.sample.yml mariadb/12/compose.yml
cp mariadb/12/sample.env mariadb/12/.env
```

在根目录 `compose.yml` 的 `include` 中加入：

```yaml
include:
  - mariadb/12/compose.yml
```

所有服务共享外部 `docker` 网络。首次使用本仓库时创建网络，再从仓库根目录构建并启动：

```sh
docker network create --driver bridge docker
docker compose build mariadb12
docker compose up -d mariadb12
```

网络已存在时跳过创建步骤。版本目录的 Compose 文件由根目录提供网络定义，直接在版本目录运行前需要补上网络定义。`up -d` 返回后，首次数据库初始化可能仍在进行，可以使用下方 SQL 命令确认是否就绪。

## 连接和账户

| 项目 | 默认值 |
|---|---|
| 服务名 | `mariadb12` |
| 宿主机连接地址 | `127.0.0.1:3307` |
| 共享网络内连接地址 | `mariadb12:3306` |
| 时区 | `Asia/Shanghai` |
| root 密码 | `root` |
| 开发账户 | `admin` / `admin` |

通过 `mariadb/12/.env` 调整密码、时区和 `MARIADB_PORT`。PHP 可以使用现有的 `pdo_mysql` 或 `mysqli` 扩展连接。

`MARIADB_ROOT_HOST=localhost` 将 root 限制为通过容器内的本地 socket 访问。普通开发账户由官方入口创建，`init/01-user-grants.sh` 再授予该用户全库权限，方便创建不同项目的数据库。

初始化脚本以可执行文件提交，加载官方入口提供的 SQL 连接、转义函数。账户创建及授权仅在空数据目录首次初始化时执行；修改 `.env` 不会更新已有数据库中的密码或权限。

## 配置和持久化

保留官方镜像内的 `/etc/mysql/my.cnf`、`/etc/mysql/mariadb.cnf` 和 `/etc/mysql/mariadb.conf.d/` 默认配置。自定义配置挂载至 `/etc/mysql/conf.d/`，在默认配置之后加载；无需复制整套系统配置或符号链接。

| 宿主机目录（相对版本目录） | 容器路径 | 用途 |
|---|---|---|
| `config/conf.d/` | `/etc/mysql/conf.d/` | 自定义配置 |
| `init/` | `/docker-entrypoint-initdb.d/` | 首次初始化脚本及 SQL |
| `data/` | `/var/lib/mariadb/` | 独立的数据目录，与 `datadir` 一致 |
| `logs/` | `/var/log/mariadb/` | binlog、错误日志、慢查询日志 |

数据目录显式设置为 `/var/lib/mariadb/`，与 Compose 数据挂载一致。基础镜像仍继承 `/var/lib/mysql` 的卷声明，可能出现未使用的匿名卷；实际数据库数据保存在宿主机 `data/` 对应的 `/var/lib/mariadb/`。

默认使用 `utf8mb4` / `utf8mb4_general_ci`，记录执行超过 3 秒的慢查询。入口脚本会为日志目录设置 mysql 所有权，再交给官方入口准备数据目录、初始化数据库并切换至 mysql 用户运行服务。

启用文件式 binlog，格式为 `ROW`，保留时间为 30 天，在启动或日志轮转时触发过期清理。单个文件达到约 100 MiB 后轮转，大事务可能超过此值。参与复制时，需要为每台服务器配置不同的 `server_id`。

仅修改数据库参数时，重启对应服务：

```sh
docker compose restart mariadb12
```

修改 Compose 挂载路径后，重建容器以应用新配置，宿主机 `data/` 和 `logs/` 目录继续保留：

```sh
docker compose up -d --force-recreate mariadb12
```

## 验证和日志

```sh
# 使用开发账户验证 TCP 连接和 binlog
docker compose exec -T mariadb12 sh -ec '
  export MYSQL_PWD="$MARIADB_PASSWORD"
  mariadb --protocol=TCP --host=127.0.0.1 --user="$MARIADB_USER" \
    --execute="SELECT VERSION(); SELECT 1; SHOW VARIABLES LIKE '\''log_bin'\''; SHOW BINARY LOGS;"
'

# 官方入口的启动日志，以及数据库错误日志
docker compose logs mariadb12
docker compose exec -T mariadb12 tail -n 100 /var/log/mariadb/error.log
```

GitHub Actions 会从空数据目录构建启动，通过有次数限制的 TCP 查询重试等待数据库就绪，再验证用户认证、跨库读写、binlog 和实际数据目录，并在重建容器及更新匿名卷后验证数据持久化。实际 `.env`、`compose.yml`、数据和日志不提交到版本控制。

参考：[官方镜像说明](https://hub.docker.com/_/mariadb)。
