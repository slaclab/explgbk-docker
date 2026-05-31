ARG MONGO_VERSION=8.0.19-7

FROM percona/percona-server-mongodb:${MONGO_VERSION}
USER root
RUN setcap cap_sys_resource=eip /usr/bin/mongod
USER 1001
