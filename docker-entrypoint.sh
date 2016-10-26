#! /bin/sh

TOMCAT_UID="${TOMCAT_UID:-1000}"
set -ux
adduser -s /bin/false -D -h $CATALINA_HOME -H -u ${TOMCAT_UID} tomcat
chown -R tomcat $CATALINA_HOME/*
chmod +x $CATALINA_HOME/bin/setenv.sh
test -n "$DOCKERIZE_CMD" && gosu tomcat $DOCKERIZE_CMD
exec gosu tomcat $CATALINA_HOME/bin/catalina.sh run
