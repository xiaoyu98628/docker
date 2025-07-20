#!/bin/sh

# 使用输入模板文件，输出到新文件（不修改原模板）
sed -e "s|\${MYSQL_USER}|${MYSQL_USER}|g" \
    /docker-entrypoint-initdb.d/init.sql.template > \
    /docker-entrypoint-initdb.d/init.sql

chown mysql:mysql /docker-entrypoint-initdb.d/init.sql
chmod 644 /docker-entrypoint-initdb.d/init.sql

# 继续原始入口点
exec /usr/local/bin/docker-entrypoint.sh "$@"