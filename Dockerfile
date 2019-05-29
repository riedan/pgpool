FROM php:7.3-fpm-alpine3.9

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
	apk add --no-cache --virtual .build-deps \
		$PHPIZE_DEPS \
		imagemagick-dev \
		libjpeg-turbo-dev \
		libpng-dev \
	; \
	\
	docker-php-ext-configure gd --with-png-dir=/usr --with-jpeg-dir=/usr; \
	docker-php-ext-install \
		bcmath \
		exif \
		gd \
		mysqli \
		opcache \
		zip \
	; \
	pecl install imagick-3.4.4; \
	docker-php-ext-enable imagick; \
	\
	runDeps="$( \
		scanelf --needed --nobanner --format '%n#p' --recursive /usr/local/lib/php/extensions \
			| tr ',' '\n' \
			| sort -u \
			| awk 'system("[ -e /usr/local/lib/" $1 " ]") == 0 { next } { print "so:" $1 }' \
	)"; \
	apk add --virtual .wordpress-phpexts-rundeps $runDeps; \
	apk del .build-deps


RUN { \
		echo 'opcache.memory_consumption=128'; \
		echo 'opcache.interned_strings_buffer=8'; \
		echo 'opcache.max_accelerated_files=4000'; \
		echo 'opcache.revalidate_freq=2'; \
		echo 'opcache.fast_shutdown=1'; \
		echo 'opcache.enable_cli=1'; \
	} > /usr/local/etc/php/conf.d/opcache-recommended.ini

RUN { \
		echo 'error_reporting = 4339'; \
		echo 'display_errors = Off'; \
		echo 'display_startup_errors = Off'; \
		echo 'log_errors = On'; \
		echo 'error_log = /dev/stderr'; \
		echo 'log_errors_max_len = 1024'; \
		echo 'ignore_repeated_errors = On'; \
		echo 'ignore_repeated_source = Off'; \
		echo 'html_errors = Off'; \
	} > /usr/local/etc/php/conf.d/error-logging.ini

RUN apk --update --no-cache add libpq=${PG_VERSION} postgresql-dev=${PG_VERSION} postgresql-client=${PG_VERSION} \
                                linux-headers gcc make libgcc g++ \
                                libffi-dev python python-dev py2-pip libffi-dev dos2unix && \
    cd /tmp && \
    wget http://www.pgpool.net/mediawiki/images/pgpool-II-${PGPOOL_VERSION}.tar.gz -O - | tar -xz && \
    chown root:root -R /tmp/pgpool-II-${PGPOOL_VERSION} && \
    cd /tmp/pgpool-II-${PGPOOL_VERSION} && \
    ./configure --prefix=/usr \
                --sysconfdir=/etc \
                --mandir=/usr/share/man \
                --infodir=/usr/share/info && \
    make && \
    make install && \
    rm -rf /tmp/pgpool-II-${PGPOOL_VERSION} && \
    apk del postgresql-dev linux-headers gcc make libgcc g++


RUN set -eux; \
  cd /tmp; && \
  wget  http://www.pgpool.net/download.php?f=pgpoolAdmin-${PGPOOL_ADMIN_VERSION}.tar.gz | tar -xz; && \
  chown root:root -R /tmp/pgpoolAdmin-${PGPOOL_ADMIN_VERSION}; && \
  mv /tmp/pgpoolAdmin-${PGPOOL_ADMIN_VERSION} /var/www/html/. ; && \
  chown -R ${SYS_USER}:${SYS_GROUP}   /var/www/html/


RUN pip install Jinja2

RUN mkdir /etc/pgpool2 /var/run/pgpool /var/log/pgpool /var/run/postgresql /var/log/postgresql/ && \
    chown ${SYS_USER}:${SYS_GROUP} -R /etc/pgpool2 /var/run/pgpool /var/log/pgpool /var/run/postgresql /var/log/postgresql

# Post Install Configuration.
ADD bin/configure-pgpool2.py /usr/bin/configure-pgpool2
RUN dos2unix /usr/bin/configure-pgpool2
RUN chmod +x /usr/bin/configure-pgpool2

ADD conf/pcp.conf.template /usr/share/pgpool2/pcp.conf.template
ADD conf/pgpool.conf.template /usr/share/pgpool2/pgpool.conf.template

# Start the container.
COPY script/docker-entrypoint.sh /
RUN dos2unix /docker-entrypoint.sh && apk del dos2unix
#make sure the file can be executed
RUN ["chmod", "+x", "/docker-entrypoint.sh"]
ENTRYPOINT ["/docker-entrypoint.sh"]

EXPOSE 9999 9898

CMD ["pgpool","-n", "-f", "/etc/pgpool2/pgpool.conf", "-F", "/etc/pgpool2/pcp.conf"]