# Tomcat and Oracle JRE in docker

Use this repo to build a small footprint docker image containing the following based on [alpine linux](https://hub.docker.com/_/alpine/):

- Tomcat (versions tested compatible with Geoserver)
- Oracle JDK 8
- gosu

The Dockerfile is adapted from the following primarily because Oracle JDK 7 is [no longer available](http://www.oracle.com/technetwork/java/javase/overview/index.html)

- https://hub.docker.com/r/sdd330/alpine-oraclejdk7/~/dockerfile/
- https://hub.docker.com/r/sdd330/alpine-tomcat-oraclejdk/

[gosu](https://github.com/tianon/gosu) has been included so that tomcat would run as non-root user for better security. The gosu stanza in the Dockerfile is based on [docker-alpine-gosu](https://github.com/mendsley/docker-alpine-gosu). The docker image uses `/docker-entrypoint.sh` to run tomcat as non-root user. The numeric UID of this user in the container defaults to 1000 but it may be overridden with the environment variable *TOMCAT_UID*.

[dockerize](https://github.com/jwilder/dockerize) may be used to wait for any dependent container (service) to be ready before starting Tomcat. To use it, define the environment variable *DOCKERIZE_CMD* with the full command, e.g. `dockerize -wait=tcp://my_postgresql_host_ip:5432 -timeout=30m`.

My personal use-case is for running [Boundless](http://boundlessgeo.com/products/opengeo-suite/) GeoServer and GeoFence.

Even though GeoServer has only been officially tested with JRE7, it seems to [work fine with JRE8](http://osdir.com/ml/geoserver-development-geospatial-java/2015-01/msg00331.html).

## Usage

Tomcat webapps directory in the container is */usr/tomcat/webapps/*


### Enable strong cryptography in JVM (recommended)

To enable strong cryptography in Oracle JRE, extract *local_policy.jar* and *US_export_policy.jar* from http://download.oracle.com/otn-pub/java/jce/7/UnlimitedJCEPolicyJDK7.zip

```
volumes:
- local_policy.jar:/usr/lib/jvm/default-jvm/jre/lib/security/local_policy.jar
- US_export_policy.jar:/usr/lib/jvm/default-jvm/jre/lib/security/US_export_policy.jar
```

### Tune JVM

Override any JRE JAVA [default values](https://github.com/cynici/tomcat/blob/master/Dockerfile) using *environment* in docker-compose.yml file. GeoServer requires MINMEM greater or equal to 64 MB.

```
environment:
  MAXMEM: 1024m
  MINMEM: 64m
```

### Persist Geoserver data

To persist GeoServer data, set its data directory to a separate directory in the container and mount it using *volumes* in docker-compose.yml

```
GEOSERVER_DATA_DIR=/var/geoserver
```

### Sample docker-compose.yml

```
geoserver:
  image: cheewai/tomcat
  environment:
  - TOMCAT_UID=1001
  - MAXMEM=2048m
  - GEOSERVER_DATA_DIR=/var/geoserver
  volumes:
  - ./downloads/local_policy.jar:/usr/lib/jvm/default-jvm/jre/lib/security/local_policy.jar
  - ./downloads/US_export_policy.jar:/usr/lib/jvm/default-jvm/jre/lib/security/US_export_policy.jar
  - ./webapps:/usr/tomcat/webapps
  - ./gsdata:/var/geoserver
  - ./setenv.sh:/usr/tomcat/bin/setenv.sh:ro
  ports:
  - "8080:8080"
```

## Download script

GeoSolution provides well-tested snapshots of stable release on a daily basis that includes the latest bug fixes.

With a little customization, this download script can be used fetch the Geoserver and any additional plugin that you require.

```
#! /bin/bash

set -eux
DLDIR=${DLDIR:-downloads}
VER="${VER:-2.12.x}"
GSVER="${GSVER:-geoserver-2.12}"
BASE_URL="https://build.geoserver.org/geoserver/$VER"
pushd $DLDIR || {
  echo "Set download directory DLDIR to an existing directory" >&2
  exit 1
}
wget --timestamping "${BASE_URL}/geoserver-${VER}-latest-war.zip"
for p in cas feature-pregeneralized imagemosaic-jdbc monitor mysql pyramid wps ; do
  wget --timestamping "${BASE_URL}/ext-latest/${GSVER}-SNAPSHOT-${p}-plugin.zip"
done
popd
```

### Initial setup script

This script is to unpack a specific version of Geoserver and any plugin already present in the download directory *DLDIR* into the Tomcat *webapps* directory.

```
#! /bin/sh

[ $# -eq 1 ] || {
  echo "usage: $0 {geoserver_webapps_dir}" >&2
  exit 1
}
APPDIR=$(readlink -f "$1")
set -eux
DLDIR=${DLDIR:-downloads}
VER="${VER:-2.12.x}"
GSVER="${GSVER:-geoserver-2.12}"

unzip -d $APPDIR "$DLDIR/geoserver-${VER}-latest-war.zip" geoserver.war
[ -d "$APPDIR/geoserver" ] && rm -f "$APPDIR/geoserver"

# Unarchive geoserver.war
docker run -it --rm -e TOMCAT_UID=1001 --entrypoint=/bin/sh -v $APPDIR:/usr/tomcat/webapps cheewai/tomcat -c "mkdir /usr/tomcat/webapps/geoserver; cd /usr/tomcat/webapps/geoserver && /usr/lib/jvm/default-jvm/bin/jar -xvf ../geoserver.war"
docker run -it --rm -e TOMCAT_UID=1001 --entrypoint=/bin/sh -v $APPDIR:/usr/tomcat/webapps cheewai/tomcat -c "chmod -R ugo+rw /usr/tomcat/webapps/geoserver"

# Unzip extensions
for f in ${DLDIR}/${GSVER}-*-plugin.zip ; do
  unzip -o -d $APPDIR/geoserver/WEB-INF/lib "$f"
done

docker run -it --rm -e TOMCAT_UID=1001 -v $APPDIR:/usr/tomcat/webapps cheewai/tomcat
```
