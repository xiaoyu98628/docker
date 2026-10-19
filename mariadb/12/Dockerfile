# 指定基于 mariadb:12 创建
FROM mariadb:12

# 镜像元数据
LABEL maintainer="XiaoYu <1765841705@qq.com>" \
    version="12" \
    description="MariaDB 12 development environment with binary logs and user initialization"

ARG TZ

# 修改时间
RUN if [ -n "${TZ}" ]; then ln -sf "/usr/share/zoneinfo/${TZ}" /etc/localtime && echo "${TZ}" > /etc/timezone; fi

COPY ./script/entrypoint.sh /usr/local/bin/mariadb-entrypoint.sh

# 使用 sed 转换 CRLF 为 LF（替代 dos2unix）
RUN sed -i 's/\r$//' /usr/local/bin/mariadb-entrypoint.sh && \
    chmod +x /usr/local/bin/mariadb-entrypoint.sh

ENTRYPOINT ["/usr/local/bin/mariadb-entrypoint.sh"]
CMD ["mariadbd"]
