FROM alpine

ENV SYS_GROUP postgres
ENV SYS_USER postgres


RUN set -eux; \
	getent group ${SYS_GROUP} || addgroup -S ${SYS_GROUP}; \
	getent passwd ${SYS_USER} || adduser -S ${SYS_USER}  -G ${SYS_GROUP} -s "/bin/sh";

ENV PGPOOL_VERSION 4.0.5

ENV PG_VERSION 11.4-r0

ENV LANG C

RUN apk update && apk upgrade \
  &&  apk --update --no-cache add libpq=${PG_VERSION} postgresql-dev=${PG_VERSION} postgresql-client=${PG_VERSION}  openssl-dev \
                                linux-headers gcc make libgcc g++ file \
                                libffi-dev python python-dev py2-pip libffi-dev tzdata openntpd ca-certificates openssl openssh git dos2unix && \
    cd /tmp && \
    wget http://www.pgpool.net/mediawiki/images/pgpool-II-${PGPOOL_VERSION}.tar.gz -O - | tar -xz && \
    chown root:root -R /tmp/pgpool-II-${PGPOOL_VERSION} && \
    cd /tmp/pgpool-II-${PGPOOL_VERSION} && \
    ./configure --prefix=/usr \
                --sysconfdir=/etc \
                --mandir=/usr/share/man \
                --infodir=/usr/share/info
                --with-openssl \
                 && \
    make && \
    make install && \
    rm -rf /tmp/pgpool-II-${PGPOOL_VERSION} && \
    apk del postgresql-dev linux-headers gcc make libgcc g++

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