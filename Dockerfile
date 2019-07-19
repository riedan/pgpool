FROM alpine

ENV SYS_GROUP postgres
ENV SYS_USER postgres


RUN set -eux; \
	getent group ${SYS_GROUP} || addgroup -S ${SYS_GROUP}; \
	getent passwd ${SYS_USER} || adduser -S ${SYS_USER}  -G ${SYS_GROUP} -s "/bin/sh";

ENV PGPOOL_VERSION 3.7.10

ENV PG_POOL_INSTALL_PATH  /opt/pgpool


ENV LANG C

RUN apk update && apk upgrade \
  &&  apk --update --no-cache  add libpq \
                                   linux-headers gcc make libgcc g++ postgresql-client postgresql-dev \
                                   libffi-dev python python-dev py2-pip openssl-dev dos2unix  bash su-exec && \
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

RUN pip install Jinja2

RUN mkdir -p /etc/pgpool2 /var/run/pgpool /var/log/pgpool /var/run/postgresql /var/log/postgresql/  /usr/share/pgpool2 && \
    chown ${SYS_USER}:${SYS_GROUP} -R /etc/pgpool2 /var/run/pgpool /var/log/pgpool /var/run/postgresql /var/log/postgresql \
     /usr/share/pgpool2

# Post Install Configuration.
ADD bin/configure-pgpool2 /usr/bin/configure-pgpool2
RUN dos2unix /usr/bin/configure-pgpool2
RUN chmod +x /usr/bin/configure-pgpool2

ADD conf/pcp.conf.template /usr/share/pgpool2/pcp.conf.template
ADD conf/pgpool.conf.template /usr/share/pgpool2/pgpool.conf.template

RUN chmod +r /usr/share/pgpool2/pcp.conf.template /usr/share/pgpool2/pgpool.conf.template

# Start the container.
COPY script/docker-entrypoint.sh /
RUN dos2unix /docker-entrypoint.sh && apk del dos2unix

#COPY ./pgpool/bin /usr/local/bin/pgpool
#COPY ./pgpool/configs /var/pgpool_configs
#make sure the file can be executed


#RUN chmod +x -R /usr/local/bin/pgpool

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


RUN ["chmod", "+x", "/docker-entrypoint.sh"]
ENTRYPOINT ["/docker-entrypoint.sh"]

EXPOSE 9999 9898

CMD ["pgpool","-n", "-f", "/etc/pgpool2/pgpool.conf", "-F", "/etc/pgpool2/pcp.conf"]