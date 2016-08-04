FROM frolvlad/alpine-oraclejdk8:latest
MAINTAINER Cheewai Lai <clai@csir.co.za>

ARG GOSU_VERSION=1.9
ARG GOSU_DOWNLOAD_URL="https://github.com/tianon/gosu/releases/download/${GOSU_VERSION}/gosu-amd64"
ARG TOMCAT_VERSION=7.0.70

# Download and install gosu
#   https://github.com/tianon/gosu/releases
RUN buildDeps='curl' HOME='/root' \
 && set -x \
 && apk add --update $buildDeps \
 && curl -o gosu -fsSL "$GOSU_DOWNLOAD_URL" > gosu-amd64 \
 && mv gosu /usr/bin/gosu \
 && chmod +x /usr/bin/gosu \
 && curl --silent --location --retry 3 --cacert /etc/ssl/certs/ca-certificates.crt "https://archive.apache.org/dist/tomcat/tomcat-7/v${TOMCAT_VERSION}/bin/apache-tomcat-${TOMCAT_VERSION}.tar.gz" \
    | gunzip \
    | tar x -C /usr/ \
 && mv /usr/apache-tomcat* /usr/tomcat \
 && apk del --purge $buildDeps
ENV JAVA_HOME=/usr/lib/jvm/default-jvm
# SET CATALINE_HOME and PATH
ENV CATALINA_HOME /usr/tomcat
ENV JMX false
ENV JMX_PORT 9004
ENV JMX_HOSTNAME localhost
ENV DEBUG_PORT 8000
ENV PERM 128m
ENV MAXPERM 256m
ENV MINMEM 128m
ENV MAXMEM 512m
ENV PATH $PATH:$CATALINA_HOME/bin
ADD setenv.sh $CATALINA_HOME/bin/
ADD docker-entrypoint.sh /docker-entrypoint.sh
ENTRYPOINT /docker-entrypoint.sh
