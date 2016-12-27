#! /bin/sh

TOMCAT_UID="${TOMCAT_UID:-1000}"
DOCKERIZE_CMD="{DOCKERIZE_CMD:-}"
set -ux
adduser -s /bin/false -D -h $CATALINA_HOME -H -u ${TOMCAT_UID} tomcat
chown -R tomcat $CATALINA_HOME/*
chmod +x $CATALINA_HOME/bin/setenv.sh
if [ -n "$DOCKERIZE_CMD" ]; then
  gosu tomcat $DOCKERIZE_CMD || exit $?
fi
exec gosu tomcat $CATALINA_HOME/bin/catalina.sh run
