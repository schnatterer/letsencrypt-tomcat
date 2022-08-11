ARG LETSENCRYPT_TOMCAT_VERSION=latest

FROM bitnami/tomcat:9.0.44-debian-10-r8 as tomcat
FROM schnatterer/letsencrypt-tomcat:${LETSENCRYPT_TOMCAT_VERSION} as letsencrypt-tomcat


FROM letsencrypt-tomcat as aggregator
# Copy letsencrypt-related stuff
RUN mv /letsencrypt /dist
ENV DEHYDRATED_BASEDIR="/certs/dehydrated"

# Copy reloding connector, so tomcat can automatically reload certificates at runtime
RUN mkdir -p /dist/opt/bitnami/tomcat/lib/
RUN cp -r /tomcat-reloading-connector/* /dist/opt/bitnami/tomcat/lib/

# set directory where dehydrated will create .well-known/acme-challenge
ENV DEHYDRATED_WELLKNOWN="/opt/bitnami/tomcat/webapps/ROOT"

# Copy examples/standalone tomcat config
COPY examples/standalone/tomcat /dist/opt/bitnami/tomcat/

# Deploy some content
RUN mkdir -p /dist/opt/bitnami/tomcat/webapps/ROOT
RUN echo 'Hello tomcat' > /dist/opt/bitnami/tomcat/webapps/ROOT/index.html


FROM tomcat
VOLUME /certs/
COPY --from=aggregator --chown=1001:0 /dist /
ENTRYPOINT [ "/meta-entrypoint.sh", "/opt/bitnami/scripts/tomcat/entrypoint.sh" ]
CMD [ "/opt/bitnami/scripts/tomcat/run.sh" ]