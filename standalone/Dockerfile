FROM bitnami/tomcat:9.0.35-debian-10-r1 as tomcat

FROM tomcat as aggregator
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

RUN mkdir -p /dist/static/.well-known/acme-challenge

COPY meta-entrypoint.sh /dist/app/
COPY etc /dist/etc
RUN mkdir /dist/certs/
RUN chmod -R 770 /dist

# Add Tomcat APR Protocol that is able of reloading certificates at runtime
RUN curl --fail -L https://keybase.io/schnatterer/pgp_keys.asc | gpg --import 
RUN curl --fail -Lo /dist/opt/bitnami/tomcat/lib/reloading-connector.jar https://repo1.maven.org/maven2/info/schnatterer/tomcat-reloading-connector/reloading-connector/${RELOADING_CONNECTOR_VERSION}/reloading-connector-${RELOADING_CONNECTOR_VERSION}.jar
RUN curl --fail -Lo /dist/opt/bitnami/tomcat/lib/reloading-connector.jar.asc https://repo1.maven.org/maven2/info/schnatterer/tomcat-reloading-connector/reloading-connector/${RELOADING_CONNECTOR_VERSION}/reloading-connector-${RELOADING_CONNECTOR_VERSION}.jar.asc
RUN gpg --batch --verify /dist/opt/bitnami/tomcat/lib/reloading-connector.jar.asc /dist/opt/bitnami/tomcat/lib/reloading-connector.jar
RUN rm /dist/opt/bitnami/tomcat/lib/reloading-connector.jar.asc

# Copy standalone tomcat config
COPY standalone/tomcat /dist/opt/bitnami/tomcat/

# Make standalone tomcat serve static files in directories used for letsencrypt challenges
RUN mkdir -p /dist/opt/bitnami/tomcat/webapps/ROOT/.well-known/acme-challenge
# It would be simpler to link ROOT -> static but it seems that tomcat does not follow symlinks when serving static content
# So just do it the other way round
RUN rm -rf /dist/static/.well-known/acme-challenge
RUN ln -s /opt/bitnami/tomcat/webapps/ROOT/.well-known/acme-challenge /dist/static/.well-known/acme-challenge

# Deploy some content
RUN echo 'Hello tomcat' > /dist/opt/bitnami/tomcat/webapps/ROOT/index.html


FROM tomcat
VOLUME /certs/
COPY --from=aggregator --chown=1001:0 /dist /
ENTRYPOINT [ "/app/meta-entrypoint.sh", "/opt/bitnami/scripts/tomcat/entrypoint.sh" ]
CMD [ "/opt/bitnami/scripts/tomcat/run.sh" ]