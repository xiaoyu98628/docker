# 指定基于 mysql:8 创建
FROM mysql:8

# 维护者信息
LABEL maintainer="XiaoYu <1765841705@qq.com>" \
    version="8"

ARG CONTAINER_PACKAGE_URL
ARG TZ
ARG MYSQL_USER

# 资源替换 更换镜像
RUN if [ ${CONTAINER_PACKAGE_URL} ];  \
    then \
      echo -e "[ol9_baseos]\n\
      name=Oracle Linux 9 BaseOS\n\
      baseurl=https://${CONTAINER_PACKAGE_URL}/oraclelinux/9/baseos/\$basearch/\n\
      gpgcheck=1\n\
      gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-oracle\n\
      \n\
      [ol9_appstream]\n\
      name=Oracle Linux 9 Application Stream\n\
      baseurl=https://${CONTAINER_PACKAGE_URL}/oraclelinux/9/appstream/\$basearch/\n\
      gpgcheck=1\n\
      gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-oracle" > /etc/yum.repos.d/oracle-linux.repo \
      microdnf clean all \
      && microdnf makecache; \
    fi

# 安装 gettext（提供 envsubst 命令）
RUN dnf install -y gettext && dnf clean all

# 修改时间
RUN if [ ${TZ} ]; then ln -sf "/usr/share/zoneinfo/${TZ}" /etc/localtime && echo "${TZ}" > /etc/timezone; fi

COPY ./init/entrypoint.sh /usr/local/bin/entrypoint.sh
COPY ./init/init.sql.template /docker-entrypoint-initdb.d/init.sql
RUN chmod +x /usr/local/bin/entrypoint.sh

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]