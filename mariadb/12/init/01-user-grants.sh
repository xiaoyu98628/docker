#!/bin/bash

set -e

# 独立执行初始化脚本，加载官方入口的 SQL 连接和转义函数。
. /usr/local/bin/docker-entrypoint.sh
docker_setup_env mariadbd

# 官方入口已创建用户，此处沿用现有 MySQL 服务的开发账户全库授权方式。
if [ -n "${MARIADB_USER:-}" ] && [ -n "${MARIADB_PASSWORD:-}" ]; then
  mariadb_user="$(docker_sql_escape_string_literal "${MARIADB_USER}")"
  mariadb_user_host="$(docker_sql_escape_string_literal "${MARIADB_USER_HOST:-%}")"
  docker_process_sql --binary-mode <<SQL
SET SESSION sql_mode=REPLACE(@@SESSION.sql_mode, 'NO_BACKSLASH_ESCAPES', '');
GRANT ALL PRIVILEGES ON *.* TO '${mariadb_user}'@'${mariadb_user_host}';
SQL
fi
