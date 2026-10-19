# 指定基于 mysql:26 创建
FROM mysql:26

# 镜像元数据
LABEL maintainer="XiaoYu <1765841705@qq.com>" \
    version="26" \
    description="MySQL 26 development environment with custom configuration and user initialization"

ARG TZ
ARG MYSQL_USER

# 修改时间
RUN if [ -n "${TZ}" ]; then ln -sf "/usr/share/zoneinfo/${TZ}" /etc/localtime && echo "${TZ}" > /etc/timezone; fi

COPY ./script/entrypoint.sh /usr/local/bin/entrypoint.sh

# 使用 sed 转换 CRLF 为 LF（替代 dos2unix）
RUN sed -i 's/\r$//' /usr/local/bin/entrypoint.sh && \
    chmod +x /usr/local/bin/entrypoint.sh

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
CMD ["mysqld"]
