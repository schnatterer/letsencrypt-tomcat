ARG JAVA_VERSION=8u252-b09-debian
ARG LETSENCRYPT_TOMCAT_VERSION=latest

FROM maven:3.6.3-jdk-8-slim as maven
FROM adoptopenjdk/openjdk8:jre${JAVA_VERSION} as jre
FROM schnatterer/letsencrypt-tomcat:${LETSENCRYPT_TOMCAT_VERSION} as letsencrypt-tomcat


FROM maven as mavencache
ENV MAVEN_OPTS=-Dmaven.repo.local=/mvn
WORKDIR /app
COPY spring-boot/pom.xml  /app/ 
RUN mvn dependency:go-offline


FROM mavencache as mavenbuild
COPY spring-boot /app/
RUN mvn package


FROM letsencrypt-tomcat as aggregator
# Copy letsencrypt-related stuff
RUN mv /letsencrypt /dist

# Copy Libraries: Apache Portable Runtime (APR) and JNI wrappers for APR used by Tomcat (libtcnative)
RUN cp -r /lib/* /dist/

# Copy app
COPY --from=mavenbuild /app/target/spring-boot-*.jar /dist/app/app.jar

FROM jre
VOLUME /certs/
COPY --from=aggregator --chown=1001:0 /dist /
USER 1001:0
ENTRYPOINT [ "/meta-entrypoint.sh", "java", "-jar", "/app/app.jar" ]