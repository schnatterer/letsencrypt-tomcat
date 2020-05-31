# This is only used as base image to get it's pre-compiled APR images
FROM bitnami/tomcat:9.0.35-debian-10-r1 as tomcat

FROM tomcat as aggregator
ARG DUMB_INIT_VERSION=1.2.2
ARG DEHYDRATED_VERSION=0.6.5
ARG RELOADING_CONNECTOR_VERSION=0.1.1
USER root

RUN apt-get update && apt-get install -y gpg 

RUN mkdir -p /dist/letsencrypt/usr/local/bin/ \
             /dist/letsencrypt/var/www/dehydrated \
             /dist/letsencrypt/static/.well-known/acme-challenge \
             /dist/tomcat-reloading-connector \
             /dist/lib/usr/local/lib 

RUN curl --fail -Lo /tmp/dumb-init_${DUMB_INIT_VERSION}_amd64 https://github.com/Yelp/dumb-init/releases/download/v${DUMB_INIT_VERSION}/dumb-init_${DUMB_INIT_VERSION}_amd64
RUN curl --fail -Lo /tmp/sha256sums https://github.com/Yelp/dumb-init/releases/download/v${DUMB_INIT_VERSION}/sha256sums
RUN cd /tmp && cat sha256sums | grep -e "dumb-init_${DUMB_INIT_VERSION}_amd64$" | sha256sum -c
RUN mv /tmp/dumb-init_* /dist/letsencrypt/usr/local/bin/dumb-init
RUN chmod +x /dist/letsencrypt/usr/local/bin/dumb-init

RUN curl --fail -Lo /tmp/dehydrated.tar.gz.asc https://github.com/dehydrated-io/dehydrated/releases/download/v${DEHYDRATED_VERSION}/dehydrated-${DEHYDRATED_VERSION}.tar.gz.asc
RUN curl --fail -Lo /tmp/dehydrated.tar.gz https://github.com/dehydrated-io/dehydrated/releases/download/v${DEHYDRATED_VERSION}/dehydrated-${DEHYDRATED_VERSION}.tar.gz
RUN curl --fail -L https://keybase.io/lukas2511/pgp_keys.asc | gpg --import 
RUN gpg --batch --verify /tmp/dehydrated.tar.gz.asc /tmp/dehydrated.tar.gz
RUN tar -C /tmp -xf /tmp/dehydrated.tar.gz
RUN mv /tmp/dehydrated-*/dehydrated /dist/letsencrypt/usr/local/bin/dehydrated

COPY meta-entrypoint.sh /dist/letsencrypt/
COPY etc /dist/letsencrypt/etc
RUN mkdir /dist/letsencrypt/certs/
RUN chmod -R 770 /dist

# Add Tomcat APR Protocol that is able of reloading certificates at runtime
RUN curl --fail -L https://keybase.io/schnatterer/pgp_keys.asc | gpg --import 
RUN curl --fail -Lo /dist/tomcat-reloading-connector/reloading-connector.jar https://repo1.maven.org/maven2/info/schnatterer/tomcat-reloading-connector/reloading-connector/${RELOADING_CONNECTOR_VERSION}/reloading-connector-${RELOADING_CONNECTOR_VERSION}.jar
RUN curl --fail -Lo /dist/tomcat-reloading-connector/reloading-connector.jar.asc https://repo1.maven.org/maven2/info/schnatterer/tomcat-reloading-connector/reloading-connector/${RELOADING_CONNECTOR_VERSION}/reloading-connector-${RELOADING_CONNECTOR_VERSION}.jar.asc
RUN gpg --batch --verify /dist/tomcat-reloading-connector/reloading-connector.jar.asc /dist/tomcat-reloading-connector/reloading-connector.jar
RUN rm /dist/tomcat-reloading-connector/reloading-connector.jar.asc

# Copy APR lib
RUN cp -r /opt/bitnami/tomcat/lib/ /tmp
RUN mv /tmp/lib/libapr* /tmp/lib/libtcnative* /dist/lib/usr/local/lib

FROM busybox:1.31.1
COPY --from=aggregator /dist /
ENTRYPOINT [ "echo", \
             "This image is not supposed to be executed. It conveniently packages the building blocks for letsencrypt tomcat.\n", \
             "See images schnatterer/letsencrypt-tomcat:standalone or schnatterer/letsencrypt-tomcat:spring-boot as example:\n", \
             "https://github.com/schnatterer/letsencrypt-tomcat" \
           ]
