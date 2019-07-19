FROM alpine

ENV SYS_GROUP postgres
ENV SYS_USER postgres


RUN set -eux; \
	getent group ${SYS_GROUP} || addgroup -S ${SYS_GROUP}; \
	getent passwd ${SYS_USER} || adduser -S ${SYS_USER}  -G ${SYS_GROUP} -s "/bin/sh";

ENV PGPOOL_VERSION 3.7.10
ENV DOCKERIZE_VERSION v0.6.1
ENV PG_POOL_INSTALL_PATH  /opt/pgpool


ENV LANG C

RUN apk update && apk upgrade \
  &&  apk --update --no-cache  add libpq openssl \
                                   linux-headers gcc make libgcc g++ postgresql-client postgresql-dev \
                                    bash su-exec && \
    mkdir -p  ${PG_POOL_INSTALL_PATH} &&  \
    cd ${PG_POOL_INSTALL_PATH} && \
    wget https://www.pgpool.net/mediawiki/images/pgpool-II-${PGPOOL_VERSION}.tar.gz -O - | tar -xz  --directory  ${PG_POOL_INSTALL_PATH}  --strip-components=1 --no-same-owner && \
    cd ${PG_POOL_INSTALL_PATH} && \
    ./configure --prefix=/usr \
                --sysconfdir=/etc \
                --mandir=/usr/share/man \
                --infodir=/usr/share/info \
                --with-openssl && \
    make && \
    make install && \
    rm -rf ${PG_POOL_INSTALL_PATH} && \
  #  rm -rf /usr/local/share/postgresql  /usr/local/lib/* /usr/local/bin/* /usr/local/include/* /docker-entrypoint-initdb.d && \
    apk del  postgresql-dev linux-headers gcc make libgcc g++
   # apk --update --no-cache  add postgresql-client


RUN wget https://github.com/jwilder/dockerize/releases/download/$DOCKERIZE_VERSION/dockerize-alpine-linux-amd64-$DOCKERIZE_VERSION.tar.gz \
    && tar -C /usr/local/bin -xzvf dockerize-alpine-linux-amd64-$DOCKERIZE_VERSION.tar.gz \
    && rm dockerize-alpine-linux-amd64-$DOCKERIZE_VERSION.tar.gz

RUN mkdir -p /etc/pgpoo2 /var/run/pgpool /var/log/pgpool /var/run/postgresql /var/log/postgresql/  /usr/share/pgpoo2 && \
    chown ${SYS_USER}:${SYS_GROUP} -R /etc/pgpoo2 /var/run/pgpool /var/log/pgpool /var/run/postgresql /var/log/postgresql \
     /usr/share/pgpoo2



COPY ./conf/bin /usr/local/bin/pgpool
COPY ./conf/configs /var/pgpool_configs
#make sure the file can be executed


RUN chmod +x -R /usr/local/bin/pgpool /usr/local/bin/dockerize

ENV CHECK_USER replication_user
ENV CHECK_PASSWORD replication_pass
ENV CHECK_PGCONNECT_TIMEOUT 10
ENV WAIT_BACKEND_TIMEOUT 120
ENV REQUIRE_MIN_BACKENDS 0
ENV SSH_ENABLE 0
ENV NOTVISIBLE "in users profile"

ENV CONFIGS_DELIMITER_SYMBOL ,
ENV CONFIGS_ASSIGNMENT_SYMBOL :
                                #CONFIGS_DELIMITER_SYMBOL and CONFIGS_ASSIGNMENT_SYMBOL are used to parse CONFIGS variable
                                # if CONFIGS_DELIMITER_SYMBOL=| and CONFIGS_ASSIGNMENT_SYMBOL=>, valid configuration string is var1>val1|var2>val2


EXPOSE 5432
EXPOSE 9898

HEALTHCHECK --interval=1m --timeout=10s --retries=5 \
  CMD /usr/local/bin/pgpool/has_write_node.sh

CMD ["/usr/local/bin/pgpool/entrypoint.sh"]