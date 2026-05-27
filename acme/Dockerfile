# 指定基于 acme.sh 官方镜像创建
FROM neilpang/acme.sh:latest

LABEL org.opencontainers.image.authors="XiaoYu <1765841705@qq.com>"

COPY config/entrypoint.sh /usr/local/bin/acme-entrypoint

RUN chmod +x /usr/local/bin/acme-entrypoint

ENTRYPOINT ["/usr/local/bin/acme-entrypoint"]
