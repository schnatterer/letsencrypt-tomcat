ARG JAVA_VERSION=8u252-b09-debian

FROM maven:3.6.3-jdk-8-slim as maven
FROM adoptopenjdk/openjdk8:jre${JAVA_VERSION} as jre
FROM bitnami/tomcat:9.0.35-debian-10-r1 as tomcat

FROM maven as mavencache
ENV MAVEN_OPTS=-Dmaven.repo.local=/mvn
WORKDIR /app
COPY spring-boot/pom.xml  /app/ 
RUN mvn dependency:go-offline

FROM mavencache as mavenbuild
COPY spring-boot /app/
RUN mvn package

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

RUN mkdir -p /dist/opt/bitnami/tomcat/webapps/ROOT/.well-known/acme-challenge 

COPY meta-entrypoint.sh /dist/app/
COPY etc /dist/etc
RUN mkdir /dist/etc/dehydrated/certs/
RUN chmod -R 770 /dist

# Copy APR lib
RUN cp -r /opt/bitnami/tomcat/lib/ /dist/app/lib
# Copy app
COPY --from=mavenbuild /app/target/spring-boot-*.jar /dist/app/app.jar

FROM jre
VOLUME /etc/dehydrated/certs/
COPY --from=aggregator --chown=1001:0 /dist /
ENV LD_LIBRARY_PATH="/app/lib:${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
USER 1001:0
ENTRYPOINT [ "/usr/local/bin/dumb-init", "--", "/app/meta-entrypoint.sh", "java", "-jar", "/app/app.jar" ]