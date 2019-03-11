#! /bin/sh
set -ux
TOMCAT_UID="${TOMCAT_UID:-1000}"
DOCKERIZE_CMD="${DOCKERIZE_CMD:-}"
# Refer to busybox 'adduser' manpage for details
adduser -s /bin/false -D -h $CATALINA_HOME -H -u ${TOMCAT_UID} tomcat
chown -R tomcat $CATALINA_HOME/*
chmod +x $CATALINA_HOME/bin/setenv.sh
exec gosu tomcat $DOCKERIZE_CMD $CATALINA_HOME/bin/catalina.sh run
