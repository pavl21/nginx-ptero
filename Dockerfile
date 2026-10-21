# /Dockerfile
# Repository: https://github.com/pavl21/nginx-ptero
#
# Basis: offizielles php:${PHP_VER}-fpm-alpine Image (docker-library/php).
# Gilt für die Tags 8.2, 8.3, 8.4, 8.5. Der Minor-Tag ist schwimmend, ein
# Neubau holt automatisch neue Patch-Versionen (z. B. Sicherheitsfixes) der
# offiziellen Basis mit. PHP 8.1 wird nicht mehr gebaut (kein
# Sicherheitssupport mehr seit 31.12.2025); das bestehende Tag 8.1 auf
# ghcr.io bleibt unverändert stehen.
#
# Build-Beispiel:
#   docker build --build-arg PHP_VER=8.4 -t ghcr.io/pavl21/nginx-ptero:8.4 .

ARG PHP_VER=8.4
FROM php:${PHP_VER}-fpm-alpine

LABEL org.opencontainers.image.source="https://github.com/pavl21/nginx-ptero"
LABEL org.opencontainers.image.description="PVQ Panel – Nginx + PHP-FPM ${PHP_VER} (Alpine, offizielle PHP-Basis)"
LABEL org.opencontainers.image.licenses="MIT"

# Die offizielle php-fpm-Basis setzt STOPSIGNAL SIGQUIT (php-fpm-eigener
# Graceful-Shutdown). Bash ignoriert SIGQUIT in Nicht-Login-Skripten per
# Default, wodurch /entrypoint.sh (Trap nur auf SIGTERM/SIGINT) gar nicht
# reagiert und "docker stop" nach Ablauf des Timeouts hart killt (SIGKILL).
# Deshalb hier wieder auf SIGTERM zurücksetzen, wie beim bisherigen Image.
STOPSIGNAL SIGTERM

# nginx kommt NICHT aus dem Alpine-Repo, sondern aus dem offiziellen
# nginx.org-Stable-Repo: Alpine 3.24 (edge) liefert nur 1.30.4, das noch 6
# mittelschwere CVEs offen hat (u. a. CVE-2026-15176, -93479, -95101, -97629,
# -97205, -90439). Gefixt ist das erst ab 1.30.6, nginx.org hat das Paket
# bereits in 1.30.6-r1. Signierschlüssel wird gegen einen fest eingetragenen
# SHA-256 geprüft (ermittelt am 2026-10-21 aus https://nginx.org/keys/nginx_signing.rsa.pub),
# Build bricht bei Abweichung ab. Repo-Zeile wird als @nginx-getaggtes Repo
# eingetragen (nicht als normales Repo), damit ausschließlich "nginx@nginx"
# von dort kommt und kein anderes Paket aus dem nginx.org-Repo gezogen wird.
RUN set -eux; \
    curl -fsSL https://nginx.org/keys/nginx_signing.rsa.pub -o /etc/apk/keys/nginx_signing.rsa.pub; \
    echo "ff7cf138acc09f2a5029300ab713fe6a1440605fca72e2bab76a4da9206fec87  /etc/apk/keys/nginx_signing.rsa.pub" | sha256sum -c -; \
    ALPINE_VER="v$(cut -d. -f1,2 /etc/alpine-release)"; \
    echo "@nginx https://nginx.org/packages/alpine/${ALPINE_VER}/main" >> /etc/apk/repositories; \
    # apk update statt --no-cache: --no-cache würde den Index für das
    # @nginx-getaggte Repo nie dauerhaft ablegen. Spätere apk-Aufrufe in
    # dieser Schicht (z. B. "apk del .build-deps") müssen aber die Zugehörigkeit
    # des "nginx@nginx"-World-Eintrags zu seinem Tag erneut auflösen können,
    # ohne Cache bricht das mit "repository tag ... does not exist" ab. Der
    # Cache wird weiter unten manuell wieder entfernt.
    apk update

# Laufzeit-Pakete (bleiben im Image) + Build-Abhängigkeiten (virtuelles Paket,
# wird nach dem Extension-Build wieder entfernt).
RUN apk add \
        bash \
        nginx@nginx \
        curl \
        unzip \
        git \
        freetype \
        libjpeg-turbo \
        libpng \
        libwebp \
        libzip \
        icu-libs \
    && apk add --virtual .build-deps \
        freetype-dev \
        libjpeg-turbo-dev \
        libpng-dev \
        libwebp-dev \
        libzip-dev \
        icu-dev \
    # gd mit freetype/jpeg/webp, dann restliche Erweiterungen nachinstallieren.
    # mbstring + OPcache sind in der offiziellen Basis bereits enthalten/aktiv.
    && docker-php-ext-configure gd --with-freetype --with-jpeg --with-webp \
    && docker-php-ext-install -j"$(nproc)" gd intl zip mysqli pdo_mysql exif \
    && apk del .build-deps \
    # Produktions-php.ini aktivieren: Das bisherige Alpine-Paket installierte
    # genau diese Datei als php.ini (einziger Unterschied: include_path).
    && cp "$PHP_INI_DIR/php.ini-production" "$PHP_INI_DIR/php.ini" \
    # php-Symlink (bisheriger Pfad /usr/bin/php, offizielles Image nutzt /usr/local/bin/php)
    && ln -sf /usr/local/bin/php /usr/bin/php \
    # Composer global installieren
    && curl -sS https://getcomposer.org/installer \
        | php -- --install-dir=/usr/local/bin --filename=composer \
    && composer --version \
    # Verzeichnisse vorbereiten
    && mkdir -p /home/container /run/nginx /var/log/nginx /var/lib/nginx/tmp \
    # Das nginx.org-Paket kompiliert (anders als das bisherige Alpine-Paket)
    # feste absolute Default-Pfade für Error-Log und Cache-Temp-Dirs ein
    # (--error-log-path=/var/log/nginx/error.log, Temp-Pfade unter
    # /var/cache/nginx/*). Die eigentliche egg-Config überschreibt diese Pfade
    # zwar auf /home/container/..., aber nginx öffnet das Error-Log schon vor
    # dem Parsen der Config einmal auf dem Default-Pfad, als Server-Container
    # (UID 988, kein root) sonst "Permission denied"-Alert beim Start, anders
    # als beim alten Alpine-Paket (dessen Default-Pfade relativ sind und damit
    # durch "-p /home/container/" überschrieben wurden). Deshalb hier gezielt
    # nur diese zwei Verzeichnisse für alle beschreibbar machen.
    && chmod 777 /var/log/nginx /var/cache/nginx \
    # apk-Cache erst jetzt entfernen (siehe Kommentar bei "apk update" oben)
    && rm -rf /var/cache/apk/*

# php-fpm8 als Wrapper-Script (wie bisher):
#   - Ruft den echten php-fpm der offiziellen Basis auf (/usr/local/sbin/php-fpm)
#   - Fügt automatisch user=root/group=root ein, falls im www.conf vergessen
RUN echo '#!/bin/sh'                                                                         > /usr/sbin/php-fpm8 \
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
    && echo 'exec /usr/local/sbin/php-fpm -R "$@"'                                             >> /usr/sbin/php-fpm8 \
    && chmod +x /usr/sbin/php-fpm8

WORKDIR /home/container

# Pterodactyl-Standard-Entrypoint:
# Wings setzt $STARTUP als Env-Variable (mit {{VAR}}-Syntax).
# Dieses Script löst die Variablen auf und startet den Server.
RUN printf '#!/bin/bash\n\
cd /home/container\n\
INTERNAL_IP=$(ip route get 1 | awk '"'"'{print $(NF-2);exit}'"'"')\n\
export INTERNAL_IP\n\
MODIFIED_STARTUP=$(echo -e ${STARTUP} | sed -e '"'"'s/{{/${/g'"'"' -e '"'"'s/}}/}/g'"'"')\n\
echo ":/home/container$ ${MODIFIED_STARTUP}"\n\
\n\
eval ${MODIFIED_STARTUP} &\n\
SERVER_PID=$!\n\
\n\
# Leitet SIGTERM/SIGINT direkt an den Server-Prozess weiter\n\
trap "kill -TERM $SERVER_PID 2>/dev/null" SIGTERM SIGINT\n\
\n\
# Liest stdin: Wings sendet ^C (\\x03) als Stop-Signal\n\
( while IFS= read -r -d '"'"''"'"' -n1 char 2>/dev/null; do\n\
    printf '"'"'%%s'"'"' "$char" | grep -qP '"'"'\\x03'"'"' && kill -TERM $SERVER_PID 2>/dev/null && break\n\
  done ) &\n\
READER_PID=$!\n\
\n\
wait $SERVER_PID\n\
kill $READER_PID 2>/dev/null\n' > /entrypoint.sh \
    && chmod +x /entrypoint.sh

CMD ["/entrypoint.sh"]
