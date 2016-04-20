FROM alpine
MAINTAINER Cheewai Lai <clai@csir.co.za>

ARG GOSU_VERSION=1.8
ENV GOSU_DOWNLOAD_URL="https://github.com/tianon/gosu/releases/download/${GOSU_VERSION}/gosu-amd64"

# Download and install gosu
#   https://github.com/tianon/gosu/releases
RUN buildDeps='curl' HOME='/root' \
	&& set -x \
	&& apk add --update $buildDeps \
	&& curl -o gosu -fsSL "$GOSU_DOWNLOAD_URL" > gosu-amd64 \
	&& mv gosu /usr/bin/gosu \
	&& chmod +x /usr/bin/gosu \
        && apk del --purge $buildDeps

#ARG JAVA_VERSION=7
#ARG JAVA_UPDATE=80
#ARG JAVA_BUILD=15
# Figure out these values manually by visiting http://www.oracle.com/technetwork/java/javase/downloads/jdk8-downloads-2133151.html
ARG JAVA_VERSION=8
ARG JAVA_UPDATE=72
ARG JAVA_BUILD=15

ENV JAVA_HOME=/usr/lib/jvm/default-jvm


# Here we use several hacks collected from https://github.com/gliderlabs/docker-alpine/issues/11:
# 1. install GLibc (which is not the cleanest solution at all)
# 2. hotfix /etc/nsswitch.conf, which is apperently required by glibc and is not used in Alpine Linux

RUN apk add --update wget bash curl ca-certificates && \
    cd /tmp && \
    wget --no-check-certificate "https://circle-artifacts.com/gh/andyshinn/alpine-pkg-glibc/6/artifacts/0/home/ubuntu/alpine-pkg-glibc/packages/x86_64/glibc-2.21-r2.apk" \
         "https://circle-artifacts.com/gh/andyshinn/alpine-pkg-glibc/6/artifacts/0/home/ubuntu/alpine-pkg-glibc/packages/x86_64/glibc-bin-2.21-r2.apk" && \
    apk add --allow-untrusted glibc-2.21-r2.apk glibc-bin-2.21-r2.apk && \
    /usr/glibc/usr/bin/ldconfig /lib /usr/glibc/usr/lib && \
    echo 'hosts: files mdns4_minimal [NOTFOUND=return] dns mdns4' >> /etc/nsswitch.conf && \
    wget --no-check-certificate --header "Cookie: oraclelicense=accept-securebackup-cookie;" \
        "http://download.oracle.com/otn-pub/java/jdk/${JAVA_VERSION}u${JAVA_UPDATE}-b${JAVA_BUILD}/jdk-${JAVA_VERSION}u${JAVA_UPDATE}-linux-x64.tar.gz" && \
    tar xzf "jdk-${JAVA_VERSION}u${JAVA_UPDATE}-linux-x64.tar.gz" && \
    mkdir -p /usr/lib/jvm && \
    mv "/tmp/jdk1.${JAVA_VERSION}.0_${JAVA_UPDATE}" "/usr/lib/jvm/java-${JAVA_VERSION}-oracle" && \
    ln -s "java-${JAVA_VERSION}-oracle" $JAVA_HOME && \
    ln -s $JAVA_HOME/bin/java /usr/bin/java && \
    ln -s $JAVA_HOME/bin/javac /usr/bin/javac && \
    rm -rf $JAVA_HOME/*src.zip && \
    rm /tmp/* /var/cache/apk/*
ENV PATH $PATH:$JAVA_HOME/bin

ENV TOMCAT_VERSION 7.0.67
RUN curl \
  --silent \
  --location \
  --retry 3 \
  --cacert /etc/ssl/certs/ca-certificates.crt \
  "https://archive.apache.org/dist/tomcat/tomcat-7/v${TOMCAT_VERSION}/bin/apache-tomcat-${TOMCAT_VERSION}.tar.gz" \
    | gunzip \
    | tar x -C /usr/ \
    && mv /usr/apache-tomcat* /usr/tomcat
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
