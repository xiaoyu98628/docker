# 指定基于 mysql:8 创建 oraclelinux-9-slim-amd64-rootfs.tar.xz
FROM mysql:8

# 维护者信息
LABEL maintainer="XiaoYu <1765841705@qq.com>"

ARG CONTAINER_PACKAGE_URL
ARG TZ
ARG MYSQL_USER

# 资源替换 更换镜像
RUN if [ ${CONTAINER_PACKAGE_URL} ]; then \
      printf '%s\n' \
        "[ol9_baseos]" \
        "name=Oracle Linux 9 BaseOS" \
        "baseurl=https://${CONTAINER_PACKAGE_URL}/oraclelinux/9/baseos/\$basearch/" \
        "gpgcheck=1" \
        "gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-oracle" \
        "" \
        "[ol9_appstream]" \
        "name=Oracle Linux 9 Application Stream" \
        "baseurl=https://${CONTAINER_PACKAGE_URL}/oraclelinux/9/appstream/\$basearch/" \
        "gpgcheck=1" \
        "gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-oracle" \
        > /etc/yum.repos.d/oracle-linux.repo; \
    fi

# 修改时间
RUN if [ ${TZ} ]; then ln -sf "/usr/share/zoneinfo/${TZ}" /etc/localtime && echo "${TZ}" > /etc/timezone; fi

COPY ./extensions/entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
CMD ["mysqld"]