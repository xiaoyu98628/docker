#!/bin/sh

set -e

# 官方入口只修正数据目录权限，这里为独立挂载的日志目录准备权限。
if [ "$(id -u)" = "0" ]; then
  mkdir -p /var/log/mariadb
  chown mysql:mysql /var/log/mariadb
fi

# 账户初始化和进程降权仍由官方入口处理。
exec /usr/local/bin/docker-entrypoint.sh "$@"
