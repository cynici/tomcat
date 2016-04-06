# Tomcat and Oracle JRE in docker

Use this repo to build a small footprint docker image containing the following based on [alpine linux](https://hub.docker.com/_/alpine/):

- Tomcat 7
- Oracle JDK 8
- gosu

The Dockerfile is adapted from the following primarily because Oracle JDK 7 is [no longer available](http://www.oracle.com/technetwork/java/javase/overview/index.html)

- https://hub.docker.com/r/sdd330/alpine-oraclejdk7/~/dockerfile/
- https://hub.docker.com/r/sdd330/alpine-tomcat-oraclejdk/

[gosu](https://github.com/tianon/gosu) has been included so that tomcat would run as non-root user for better security. The gosu stanza in the Dockerfile is based on [docker-alpine-gosu](https://github.com/mendsley/docker-alpine-gosu)

My personal use-case is for running [Boundless](http://boundlessgeo.com/products/opengeo-suite/) GeoServer and GeoFence.

Even though GeoServer has only been officially tested with JRE7, it seems to [work fine with JRE8](http://osdir.com/ml/geoserver-development-geospatial-java/2015-01/msg00331.html).

## Usage

To run tomcat as non-root user with specific numeric UID, write your own entrypoint script using *docker-entrypoint.sh* as example.

```
#! /bin/sh

TOMCAT_UID="${TOMCAT_UID:-1000}"
set -eux
adduser -s /bin/false -D -h $CATALINA_HOME -H -u ${TOMCAT_UID} tomcat \
 && chown -R tomcat $CATALINA_HOME/* \
 && chmod +x $CATALINA_HOME/bin/setenv.sh
gosu tomcat catalina.sh run
```

## Notes

- Environment variables JAVA\_\* are hardcoded to enable non-interactive download from Oracle web site. You figure out these values manually by visiting http://www.oracle.com/technetwork/java/javase/downloads/jdk8-downloads-2133151.html and update them accordingly

- Environment variable TOMCAT\_VERSION is determined from https://tomcat.apache.org/download-70.cgi

- *catalina.sh* honors environment variable JAVA\_OPTS so you can tuning the JVM by passing it when launching the container

```
JAVA_OPTS="-Djava.awt.headless=true -Xmx2048m -Xms512m 
-XX:SoftRefLRUPolicyMSPerMB=36000 -XX:+UseParallelGC 
-DADVANCED_PROJECTION_HANDLING=true -DUSE_STREAMING_RENDERER=true"
```

- Specifically for GeoServer, persist it data outside the container:

```
GEOSERVER_DATA_DIR=/var/geoserver
```
