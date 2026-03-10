# 指定基于 nginx:1.29-alpine 创建
FROM nginx:1.29-alpine

LABEL org.opencontainers.image.authors="XiaoYu <1765841705@qq.com>"

ARG TZ
ARG CONTAINER_PACKAGE_URL

# 资源替换 更换镜像
RUN if [ ${CONTAINER_PACKAGE_URL} ]; then sed -i "s/dl-cdn.alpinelinux.org/${CONTAINER_PACKAGE_URL}/g" /etc/apk/repositories; fi

# 修改时间
RUN if [ ${TZ} ]; then apk add --no-cache --virtual .time-deps tzdata && cp -r "/usr/share/zoneinfo/${TZ}" /etc/localtime && echo "${TZ}" > /etc/timezone && apk del .time-deps; fi

WORKDIR /usr/share/nginx/html
