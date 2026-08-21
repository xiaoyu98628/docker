# 指定基于 acme.sh 官方镜像创建
FROM neilpang/acme.sh:latest

LABEL org.opencontainers.image.authors="XiaoYu <1765841705@qq.com>"

ARG CONTAINER_PACKAGE_URL
ARG TZ

# 资源替换 更换镜像
RUN if [ -n "${CONTAINER_PACKAGE_URL}" ]; then \
      sed -i "s/dl-cdn.alpinelinux.org/${CONTAINER_PACKAGE_URL}/g" /etc/apk/repositories; \
    fi \
    && if [ -n "${TZ}" ]; then \
      apk add --no-cache --virtual .time-deps tzdata \
      && cp "/usr/share/zoneinfo/${TZ}" /etc/localtime \
      && echo "${TZ}" > /etc/timezone \
      && apk del .time-deps; \
    fi

COPY scripts/acme-entrypoint.sh /usr/local/bin/acme-entrypoint

RUN chmod +x /usr/local/bin/acme-entrypoint

ENTRYPOINT ["/usr/local/bin/acme-entrypoint"]
