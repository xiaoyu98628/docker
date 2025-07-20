#!/bin/sh

envsubst < /docker-entrypoint-initdb.d/init.template.sql > /docker-entrypoint-initdb.d/init.sql
