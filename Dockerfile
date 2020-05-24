FROM bitnami/tomcat:9.0.35-debian-10-r1 as tomcat

FROM tomcat as aggregator-user
ARG DUMB_INIT_VERSION=1.2.2
ARG DEHYDRATED_VERSION=0.6.5
ARG RELOADING_CONNECTOR_VERSION=0.1.1
USER root

RUN apt-get update && apt-get install -y gpg 

RUN mkdir -p /dist/app /dist/usr/local/bin/ /dist/var/www/dehydrated /dist/opt/bitnami/tomcat/lib/

RUN curl --fail -Lo /tmp/dumb-init_${DUMB_INIT_VERSION}_amd64 https://github.com/Yelp/dumb-init/releases/download/v${DUMB_INIT_VERSION}/dumb-init_${DUMB_INIT_VERSION}_amd64
RUN curl --fail -Lo /tmp/sha256sums https://github.com/Yelp/dumb-init/releases/download/v${DUMB_INIT_VERSION}/sha256sums
RUN cd /tmp && cat sha256sums | grep -e "dumb-init_${DUMB_INIT_VERSION}_amd64$" | sha256sum -c
RUN mv /tmp/dumb-init_* /dist/usr/local/bin/dumb-init
RUN chmod +x /dist/usr/local/bin/dumb-init

RUN curl --fail -Lo /tmp/dehydrated.tar.gz.asc https://github.com/dehydrated-io/dehydrated/releases/download/v${DEHYDRATED_VERSION}/dehydrated-${DEHYDRATED_VERSION}.tar.gz.asc
RUN curl --fail -Lo /tmp/dehydrated.tar.gz https://github.com/dehydrated-io/dehydrated/releases/download/v${DEHYDRATED_VERSION}/dehydrated-${DEHYDRATED_VERSION}.tar.gz
RUN curl --fail -L https://keybase.io/lukas2511/pgp_keys.asc | gpg --import 
RUN gpg --batch --verify /tmp/dehydrated.tar.gz.asc /tmp/dehydrated.tar.gz
RUN tar -C /tmp -xf /tmp/dehydrated.tar.gz
RUN mv /tmp/dehydrated-*/dehydrated /dist/usr/local/bin/dehydrated

RUN curl --fail -L https://keybase.io/schnatterer/pgp_keys.asc | gpg --import 
RUN curl --fail -Lo /dist/opt/bitnami/tomcat/lib/reloading-connector.jar https://repo1.maven.org/maven2/info/schnatterer/tomcat-reloading-connector/reloading-connector/${RELOADING_CONNECTOR_VERSION}/reloading-connector-${RELOADING_CONNECTOR_VERSION}.jar
RUN curl --fail -Lo /dist/opt/bitnami/tomcat/lib/reloading-connector.jar.asc https://repo1.maven.org/maven2/info/schnatterer/tomcat-reloading-connector/reloading-connector/${RELOADING_CONNECTOR_VERSION}/reloading-connector-${RELOADING_CONNECTOR_VERSION}.jar.asc
RUN gpg --batch --verify /dist/opt/bitnami/tomcat/lib/reloading-connector.jar.asc /dist/opt/bitnami/tomcat/lib/reloading-connector.jar
RUN rm /dist/opt/bitnami/tomcat/lib/reloading-connector.jar.asc

RUN mkdir -p /dist/opt/bitnami/tomcat/webapps/ROOT/.well-known/acme-challenge 

COPY tomcat /dist/opt/bitnami/tomcat/
COPY meta-entrypoint.sh /dist/app/
COPY etc /dist/etc
RUN mkdir /dist/etc/dehydrated/certs/
RUN chmod -R 770 /dist

FROM tomcat
VOLUME /etc/dehydrated/certs/
COPY --from=aggregator-user --chown=1001:0 /dist /
ENTRYPOINT [ "/usr/local/bin/dumb-init", "--", "/app/meta-entrypoint.sh" ]
CMD [ "/opt/bitnami/scripts/tomcat/run.sh" ]