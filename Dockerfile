# /Dockerfile
# Repository: https://github.com/pavl21/nginx-ptero
#
# Build-Beispiel:
#   docker build --build-arg PHP_PKG=php82 --build-arg PHP_VER=8.2 \
#                --build-arg ALPINE_VERSION=3.19 \
#                -t ghcr.io/pavl21/nginx-ptero:8.2 .

ARG ALPINE_VERSION=3.20
FROM alpine:${ALPINE_VERSION}

ARG PHP_PKG=php83
ARG PHP_VER=8.3

LABEL org.opencontainers.image.source="https://github.com/pavl21/nginx-ptero"
LABEL org.opencontainers.image.description="PVQ Panel – Nginx + PHP-FPM ${PHP_VER} (Alpine)"
LABEL org.opencontainers.image.licenses="MIT"

RUN apk --no-cache add \
        nginx \
        curl \
        unzip \
        git \
        "${PHP_PKG}" \
        "${PHP_PKG}-fpm" \
        "${PHP_PKG}-cli" \
        "${PHP_PKG}-curl" \
        "${PHP_PKG}-gd" \
        "${PHP_PKG}-mbstring" \
        "${PHP_PKG}-xml" \
        "${PHP_PKG}-zip" \
        "${PHP_PKG}-pdo" \
        "${PHP_PKG}-pdo_mysql" \
        "${PHP_PKG}-mysqli" \
        "${PHP_PKG}-opcache" \
        "${PHP_PKG}-intl" \
        "${PHP_PKG}-exif" \
        "${PHP_PKG}-fileinfo" \
        "${PHP_PKG}-tokenizer" \
        "${PHP_PKG}-ctype" \
        "${PHP_PKG}-session" \
        "${PHP_PKG}-iconv" \
        "${PHP_PKG}-phar" \
    # Einheitliche Symlinks – start.sh ruft immer php-fpm8 und php auf
    # Alpine-Binary: /usr/sbin/php-fpm84 (nicht php84-fpm!)
    && ln -sf "/usr/sbin/php-fpm$(echo ${PHP_PKG} | sed 's/php//')" /usr/sbin/php-fpm8 \
    && ln -sf "/usr/bin/${PHP_PKG}" /usr/bin/php \
    # Composer global installieren
    && curl -sS https://getcomposer.org/installer \
        | php -- --install-dir=/usr/local/bin --filename=composer \
    && composer --version \
    # Verzeichnisse vorbereiten
    && mkdir -p /home/container /run/nginx /var/log/nginx /var/lib/nginx/tmp

WORKDIR /home/container
