# 指定基于 mysql:8 创建
FROM mysql:8

# 维护者信息
LABEL maintainer="XiaoYu <1765841705@qq.com>" \
    version="8"

ARG TZ

# 修改时间
RUN if [ ${TZ} ]; then ln -sf "/usr/share/zoneinfo/${TZ}" /etc/localtime && echo "${TZ}" > /etc/timezone; fi


COPY ./init/entrypoint.sh /usr/local/bin/entrypoint.sh
COPY ./init/init.sql.template /docker-entrypoint-initdb.d/init.sql
RUN chmod +x /usr/local/bin/entrypoint.sh

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]