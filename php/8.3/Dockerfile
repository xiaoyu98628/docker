# 指定基于 php:8.3-fpm-alpine 创建
FROM php:8.3-fpm-alpine

# 维护者信息
LABEL maintainer="XiaoYu <1765841705@qq.com>" \
    version="8.3" \
    description="PHP 8.3 FPM with common extensions based on Alpine Linux"

ARG CONTAINER_PACKAGE_URL
ARG PHP_EXTENSIONS
ARG COMPOSER_IMAGE_URL
ARG TZ

ENV EXTENSIONS=",${PHP_EXTENSIONS},"

# 资源替换 更换镜像
RUN if [ -n "${CONTAINER_PACKAGE_URL}" ]; then sed -i "s/dl-cdn.alpinelinux.org/${CONTAINER_PACKAGE_URL}/g" /etc/apk/repositories; fi

# 修改时间
RUN if [ -n "${TZ}" ]; then apk add --no-cache --virtual .fetch-deps tzdata && cp -r "/usr/share/zoneinfo/${TZ}" /etc/localtime && echo "${TZ}" > /etc/timezone && apk del .fetch-deps; fi

# 引入 composer
COPY --from=composer/composer:latest /usr/bin/composer /usr/bin/composer
# 引入 install-php-extensions 脚本 方便容器内安装扩展
COPY --from=mlocati/php-extension-installer:latest /usr/bin/install-php-extensions /usr/local/bin/

# 引入 docker-entrypoint 脚本 清理残留 socket 文件
ADD ./config/extensions/docker-entrypoint /usr/local/bin/

RUN chmod +x /usr/local/bin/docker-entrypoint \
    && apk add --no-cache --virtual .dos-deps dos2unix \
    # 修改换行格式 将 Windows 下 CRLF 转换成 LF \
    && dos2unix /usr/local/bin/docker-entrypoint \
    && apk del .dos-deps

# 更新包索引 安装扩展
RUN apk update && apk upgrade \
    && if [ -n "${PHP_EXTENSIONS}" ]; \
        then \
            echo "---------- Install PHP extensions ----------" \
            && PHP_EXTENSION_LIST="$(printf '%s' "${PHP_EXTENSIONS}" | tr ',' ' ')" \
            && if [ -z "${EXTENSIONS##*,phalcon,*}" ]; then export CFLAGS="-Wno-incompatible-pointer-types"; fi \
            && install-php-extensions ${PHP_EXTENSION_LIST}; \
        fi \
    && if [ -z "${EXTENSIONS##*,swoole,*}" ]; \
        then \
            echo "---------- Configure swoole ----------" \
            && echo "[swoole]" >> /usr/local/etc/php/conf.d/docker-php-ext-swoole.ini \
            && echo "swoole.enable_fiber_mock = On" >> /usr/local/etc/php/conf.d/docker-php-ext-swoole.ini; \
        fi \
    && if [ -z "${EXTENSIONS##*,xdebug,*}" ]; \
        then \
            echo "---------- Configure xdebug ----------" \
            && echo "[xdebug]" >> /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini \
            && echo "xdebug.mode = debug" >> /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini \
            && echo "xdebug.start_with_request = yes ; 请求开始时自动开启" >> /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini \
            && echo "xdebug.start_upon_error = yes" >> /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini \
            && echo "xdebug.discover_client_host = true" >> /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini \
            && echo "xdebug.client_port = 9010" >> /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini \
            && echo "xdebug.idekey = PHPSTORM" >> /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini \
            && echo "xdebug.client_host = host.docker.internal ;phpstorm 官方文档上面有写 https://www.jetbrains.com/help/phpstorm/configuring-xdebug.html#feac0d97" >> /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini; \
        fi \
    && if [ -z "${EXTENSIONS##*,grpc,*}" ]; \
        then \
            echo "---------- Configure grpc ----------" \
            && echo "[grpc]" >> /usr/local/etc/php/conf.d/docker-php-ext-grpc.ini \
            && echo "grpc.enable_fork_support = 1" >> /usr/local/etc/php/conf.d/docker-php-ext-grpc.ini; \
        fi \
    # 替换 composer 镜像 \
    && if [ -n "${COMPOSER_IMAGE_URL}" ]; then composer config -g repo.packagist composer ${COMPOSER_IMAGE_URL}; fi \
    && echo "---------- Install supervisor ----------" \
    && apk add --no-cache supervisor \
    # 删除 pecl 下载的扩展包 \
    && rm -rf /tmp/pear \
    # 删除 apk 下载的包 \
    && rm -rf /var/cache/apk/*

ENTRYPOINT ["docker-entrypoint"]
CMD ["supervisord", "-c", "/etc/supervisord.conf", "-n"]
