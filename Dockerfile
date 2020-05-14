FROM bitnami/tomcat:9.0.34-debian-10-r8 as tomcat

FROM tomcat as aggregator-user
ARG DUMB_INIT_VERSION=1.2.2
ARG DEHYDRATED_VERSION=0.6.5
ARG RELOADING_CONNECTOR_VERSION=0.1.1
USER root
RUN mkdir -p /dist/app /dist/usr/local/bin/ /dist/var/www/dehydrated /dist/opt/bitnami/tomcat/lib/
RUN curl -Lo /dist/usr/local/bin/dumb-init https://github.com/Yelp/dumb-init/releases/download/v${DUMB_INIT_VERSION}/dumb-init_${DUMB_INIT_VERSION}_amd64 && \
    chmod +x /dist/usr/local/bin/dumb-init
    
RUN mkdir -p /dist/etc/authbind/byport/ && \
    touch /dist/etc/authbind/byport/443 /dist/etc/authbind/byport/80 && \
    chown 1001:0 /dist/etc/authbind/byport/* && \
    chmod 550 /dist/etc/authbind/byport/*
    
# TODO validate https://github.com/dehydrated-io/dehydrated/releases/download/v0.6.5/dehydrated-0.6.5.tar.gz.asc
RUN curl -Lo /dist/usr/local/bin/dehydrated https://raw.githubusercontent.com/dehydrated-io/dehydrated/v${DEHYDRATED_VERSION}/dehydrated && \
    chmod +x /dist/usr/local/bin/dehydrated
RUN curl -o /dist/opt/bitnami/tomcat/lib/reloading-connector.jar https://repo1.maven.org/maven2/info/schnatterer/tomcat-reloading-connector/reloading-connector/${RELOADING_CONNECTOR_VERSION}/reloading-connector-${RELOADING_CONNECTOR_VERSION}.jar

RUN mkdir -p /dist/opt/bitnami/tomcat/webapps/ROOT/.well-known/acme-challenge 

COPY tomcat /dist/opt/bitnami/tomcat/
COPY meta-entrypoint.sh /dist/app/
COPY createCerts.sh /dist/app/
COPY etc /dist/etc
RUN chmod -R 770 /dist

# TODO we dont need authbind, 8443 will do!
FROM tomcat as aggregator-root
USER root
RUN apt-get update
RUN cd /tmp && apt-get download authbind
RUN dpkg-deb -X /tmp/*.deb /dist
    
FROM tomcat
COPY --from=aggregator-user --chown=1001:0 /dist /
COPY --from=aggregator-root /dist /
ENTRYPOINT [ "/usr/local/bin/dumb-init", "--", "/app/meta-entrypoint.sh" ]
CMD [ "/opt/bitnami/scripts/tomcat/run.sh" ]