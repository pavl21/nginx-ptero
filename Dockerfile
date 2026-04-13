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
        bash \
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
    # php-Symlink
    && ln -sf "/usr/bin/${PHP_PKG}" /usr/bin/php \
    # Composer global installieren
    && curl -sS https://getcomposer.org/installer \
        | php -- --install-dir=/usr/local/bin --filename=composer \
    && composer --version \
    # Verzeichnisse vorbereiten
    && mkdir -p /home/container /run/nginx /var/log/nginx /var/lib/nginx/tmp

# php-fpm8 als Wrapper-Script:
#   - Ruft den echten php-fpmXX auf
#   - Fügt automatisch user=root/group=root ein, falls im www.conf vergessen
RUN PHP_NUM="$(echo ${PHP_PKG} | sed 's/php//')" \
    && echo '#!/bin/sh'                                                                         > /usr/sbin/php-fpm8 \
    && echo 'C="" p=""'                                                                        >> /usr/sbin/php-fpm8 \
    && echo 'for a in "$@"; do'                                                                >> /usr/sbin/php-fpm8 \
    && echo '  [ "$p" = "--fpm-config" ] && C="$a"'                                           >> /usr/sbin/php-fpm8 \
    && echo '  p="$a"'                                                                         >> /usr/sbin/php-fpm8 \
    && echo 'done'                                                                             >> /usr/sbin/php-fpm8 \
    && echo 'if [ -f "$C" ]; then'                                                             >> /usr/sbin/php-fpm8 \
    && echo '  INC=$(awk '"'"'/^include/{print $NF}'"'"' "$C")'                               >> /usr/sbin/php-fpm8 \
    && echo '  for f in $INC; do'                                                              >> /usr/sbin/php-fpm8 \
    && echo '    [ -f "$f" ] || continue'                                                      >> /usr/sbin/php-fpm8 \
    && echo '    grep -q "^user" "$f" 2>/dev/null && continue'                                >> /usr/sbin/php-fpm8 \
    && echo '    awk '"'"'/^\[www\]/{print;print "user  = root";print "group = root";next}{print}'"'"' "$f" > "$f.tmp" && mv "$f.tmp" "$f"' >> /usr/sbin/php-fpm8 \
    && echo '  done'                                                                           >> /usr/sbin/php-fpm8 \
    && echo 'fi'                                                                               >> /usr/sbin/php-fpm8 \
    && printf 'exec /usr/sbin/php-fpm%s -R "$@"\n' "${PHP_NUM}"                               >> /usr/sbin/php-fpm8 \
    && chmod +x /usr/sbin/php-fpm8

WORKDIR /home/container

# Pterodactyl-Standard-Entrypoint:
# Wings setzt $STARTUP als Env-Variable (mit {{VAR}}-Syntax).
# Dieses Script löst die Variablen auf und startet den Server.
RUN printf '#!/bin/bash\ncd /home/container\nINTERNAL_IP=$(ip route get 1 | awk '"'"'{print $(NF-2);exit}'"'"')\nexport INTERNAL_IP\nMODIFIED_STARTUP=$(echo -e ${STARTUP} | sed -e '"'"'s/{{/${/g'"'"' -e '"'"'s/}}/}/g'"'"')\necho ":/home/container$ ${MODIFIED_STARTUP}"\neval ${MODIFIED_STARTUP}\n' > /entrypoint.sh \
    && chmod +x /entrypoint.sh

CMD ["/entrypoint.sh"]
