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

Tomcat webapps directory in the container is */usr/tomcat/webapps/*

To enable strong cryptography in Oracle JRE, extract *local_policy.jar* and *US_export_policy.jar* from http://download.oracle.com/otn-pub/java/jce/7/UnlimitedJCEPolicyJDK7.zip

```
volumes:
- local_policy.jar:/usr/lib/jvm/default-jvm/jre/lib/security/local_policy.jar
- US_export_policy.jar:/usr/lib/jvm/default-jvm/jre/lib/security/US_export_policy.jar
```

To run tomcat as non-root user with specific numeric UID, write your own entrypoint script using *docker-entrypoint.sh* as example and set the environment variable *TOMCAT_UID*

```
#! /bin/sh

TOMCAT_UID="${TOMCAT_UID:-1000}"
set -eux
adduser -s /bin/false -D -h $CATALINA_HOME -H -u ${TOMCAT_UID} tomcat \
 && chown -R tomcat $CATALINA_HOME/* \
 && chmod +x $CATALINA_HOME/bin/setenv.sh
exec gosu tomcat catalina.sh run
```

Override any JRE JAVA [default values](https://github.com/cynici/tomcat/blob/master/Dockerfile) using *environment* in docker-compose.yml file. GeoServer requires MINMEM greater or equal to 64 MB.

```
environment:
  MAXMEM: 1024m
  MINMEM: 64m
```

Specifically to persist GeoServer data, set its data directory to a separate directory in the container and mount it using *volumes* in docker-compose.yml

```
GEOSERVER_DATA_DIR=/var/geoserver
```
