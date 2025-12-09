# 指定基于 mysql:9 创建
FROM mysql:9

# 维护者信息
LABEL maintainer="XiaoYu <1765841705@qq.com>"

ARG TZ
ARG MYSQL_USER

# 修改时间
RUN if [ ${TZ} ]; then ln -sf "/usr/share/zoneinfo/${TZ}" /etc/localtime && echo "${TZ}" > /etc/timezone; fi

COPY ./extensions/entrypoint.sh /usr/local/bin/entrypoint.sh

# 使用 sed 转换 CRLF 为 LF（替代 dos2unix）
RUN sed -i 's/\r$//' /usr/local/bin/entrypoint.sh && \
    chmod +x /usr/local/bin/entrypoint.sh

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
CMD ["mysqld"]
