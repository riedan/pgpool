FROM alpine:3.9

ENV SYS_GROUP postgres
ENV SYS_USER postgres


RUN set -eux; \
	getent group ${SYS_GROUP} || addgroup -S ${SYS_GROUP}; \
	getent passwd ${SYS_USER} || adduser -S ${SYS_USER}  -G ${SYS_GROUP} -s "/bin/sh";

ENV PGPOOL_VERSION 4.0.5
ENV PGPOOL_ADMIN_VERSION 4.0.1
ENV PG_VERSION 11.3-r0

ENV LANG C

RUN set -ex; \
	\
	apk update; \
	apk add --no-cache curl  dos2unix bash;

# Add basics first
RUN apk update && apk upgrade && apk add --no-cache \
	apache2 php7-apache2  ca-certificates openssl openssh git php7 php7-phar php7-json php7-iconv php7-openssl tzdata openntpd

# Add Composer
RUN curl -sS https://getcomposer.org/installer | php && mv composer.phar /usr/local/bin/composer

# Setup apache and php
RUN apk add --no-cache \
	php7-ftp \
	php7-xdebug \
	php7-mcrypt \
	php7-mbstring \
	php7-soap \
	php7-gmp \
	php7-pdo_odbc \
	php7-dom \
	php7-pdo \
	php7-zip \
	php7-mysqli \
	php7-sqlite3 \
	php7-pdo_pgsql \
	php7-bcmath \
	php7-gd \
	php7-odbc \
	php7-pdo_mysql \
	php7-pdo_sqlite \
	php7-gettext \
	php7-xmlreader \
	php7-xmlwriter \
	php7-tokenizer \
	php7-xmlrpc \
	php7-bz2 \
	php7-pdo_dblib \
	php7-curl \
	php7-ctype \
	php7-session \
	php7-redis \
	php7-exif

RUN apk add php7-simplexml php7-posix php7-pgsql

RUN cp /usr/bin/php7 /usr/bin/php

# Add apache to run and configure
RUN  sed -i "s/#LoadModule\ rewrite_module/LoadModule\ rewrite_module/" /etc/apache2/httpd.conf \
    && sed -i "s/#LoadModule\ session_module/LoadModule\ session_module/" /etc/apache2/httpd.conf \
    && sed -i "s/#LoadModule\ session_cookie_module/LoadModule\ session_cookie_module/" /etc/apache2/httpd.conf \
    && sed -i "s/#LoadModule\ session_crypto_module/LoadModule\ session_crypto_module/" /etc/apache2/httpd.conf \
    && sed -i "s/#LoadModule\ deflate_module/LoadModule\ deflate_module/" /etc/apache2/httpd.conf \
    && sed -i "s#^DocumentRoot \".*#DocumentRoot \"/app/public\"#g" /etc/apache2/httpd.conf \
    && sed -i "s#/var/www/localhost/htdocs#/app/public#" /etc/apache2/httpd.conf \
    && printf "\n<Directory \"/app/public\">\n\tAllowOverride All\n</Directory>\n" >> /etc/apache2/httpd.conf

RUN mkdir /app && mkdir /app/public && chown -R apache:apache /app && chmod -R 755 /app && mkdir bootstrap

RUN set -eux && \
  cd /tmp &&  \
  curl -Ls  http://www.pgpool.net/mediawiki/images/pgpoolAdmin-${PGPOOL_ADMIN_VERSION}.tar.gz | tar -xz --directory "/app/public" --strip-components=1 --no-same-owner 

RUN wget  https://github.com/noqcks/gucci/releases/download/v0.0.4/gucci-v0.0.4-linux-amd64  \
    && chmod +x gucci-v0.0.4-linux-amd64 \
    && mv gucci-v0.0.4-linux-amd64 /usr/local/bin/gucci \
    && mkdir -p /var/run/pgpool/ /etc/pgpool2/

RUN apk add --update --no-cache pgpool \
	&& mkdir -p /etc/pgpool2/

ENV PCP_PORT 9898
ENV PCP_USERNAME postgres
ENV PCP_PASSWORD postgres
ENV PGPOOL_PORT 5432
ENV PGPOOL_BACKENDS postgres:5432:10
ENV TRUST_NETWORK 0.0.0.0/0
ENV PG_USERNAME postgres
ENV PG_PASSWORD postgres

ENV NUM_INIT_CHILDREN 32
ENV MAX_POOL 4
ENV CHILD_LIFE_TIME 300
ENV CHILD_MAX_CONNECTIONS 0
ENV CONNECTION_LIFE_TIME 0
ENV CLIENT_IDLE_LIMIT 0



ADD conf/pcp.conf.template /usr/share/pgpool2/pcp.conf.template
ADD conf/pgpool.conf.template /usr/share/pgpool2/pgpool.conf.template
ADD conf/pool_hba.conf.template /usr/share/pgpool2/pool_hba.conf.template
RUN dos2unix /usr/share/pgpool2/pcp.conf.template
RUN dos2unix /usr/share/pgpool2/pgpool.conf.template
RUN dos2unix /usr/share/pgpool2/pool_hba.conf.template

# Start the container.
COPY script/docker-entrypoint.sh /
RUN dos2unix /docker-entrypoint.sh && apk del dos2unix
#make sure the file can be executed
RUN ["chmod", "+x", "/docker-entrypoint.sh"]
ENTRYPOINT ["/docker-entrypoint.sh"]


EXPOSE 9898
EXPOSE 5432
EXPOSE 80

CMD ["httpd" , "-D", "FOREGROUND"]
