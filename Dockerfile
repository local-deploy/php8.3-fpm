FROM php:8.3-fpm

LABEL maintainer="dl@varme.pw"

ENV TZ=Europe/Moscow

ARG COMPOSER_VERSION="2.6.6"
ARG UID=1000
ARG GID=1000

RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

RUN set -ex && apt-get update && apt-get install -y ssmtp wget git nano libmemcached-dev zlib1g-dev libssl-dev

COPY --from=mlocati/php-extension-installer /usr/bin/install-php-extensions /usr/local/bin/

RUN  IPE_GD_WITHOUTAVIF=1 IPE_ICU_EN_ONLY=1 IPE_KEEP_SYSPKG_CACHE=1 install-php-extensions \
     bcmath \
     exif \
     gd \
     gmp \
     imagick \
     intl \
     ldap \
     mysqli \
     opcache \
     pcntl \
     pdo_mysql \
     pdo_pgsql \
     pgsql \
     soap \
     sockets \
     xdebug \
     zip

RUN  IPE_ICU_EN_ONLY=1 IPE_DONT_ENABLE=1 install-php-extensions \
     memcache \
     memcached \
     redis \
     xhprof

RUN install-php-extensions @composer-${COMPOSER_VERSION}

RUN groupadd --gid ${GID} ${GID} && \
    usermod --non-unique --uid ${UID} www-data && \
    usermod --gid ${GID} www-data

RUN mkdir /var/www/.composer && \
    mkdir /var/www/.ssh

RUN chown www-data:www-data /var/www -R && \
    chown www-data:www-data /usr/local/etc/php/conf.d -R && \
    chown www-data:www-data /var/www/.composer && \
    chown www-data:www-data /var/www/.ssh

COPY php.ini /usr/local/etc/php
COPY ssmtp.conf /etc/ssmtp/
COPY .bashrc /var/www/
COPY docker-entrypoint.sh /entrypoint.sh

RUN chmod +x /entrypoint.sh

WORKDIR /var/www
USER www-data:www-data

ENTRYPOINT ["/entrypoint.sh"]
CMD ["php-fpm"]
