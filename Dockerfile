#FROM node:8.10.0-alpine
# Reproduces the live prod image slaclab/explgbk-docker:20240112.0.0 (checked 2026-11-06).
# That image was built from this Dockerfile's alpine:3.7 version (before 23cf773 moved to alpine:3.15).
# Versions below are pinned to what is installed in the live pod.
FROM alpine:3.7

MAINTAINER Yee-Ting Li <yee379@gmail.com>

ENV APP_DIR /app
ENV GUNICORN_PORT=8000
ENV GUNICORN_USER=gunicorn

RUN adduser -D -h $APP_DIR $GUNICORN_USER

RUN apk add --no-cache bash file git nginx uwsgi uwsgi-python python3 openldap-clients \
    gcc libffi-dev python3-dev musl-dev libressl-dev curl curl-dev nodejs \
    imagemagick
#nodejs \

COPY ldap.conf /etc/openldap/ldap.conf    
COPY entrypoint.sh /entrypoint.sh

WORKDIR ${APP_DIR}
COPY explgbk/ ${APP_DIR}/
ENV GUNICORN_MODULE=start
ENV GUNICORN_CALLABLE=app

# requirements-live.txt pins every package, including the flask_authnz and flask_socket_util
# commits, which explgbk/requirements.txt pulls from git HEAD.
COPY requirements-live.txt /tmp/requirements-live.txt
RUN python3 -m ensurepip \
    && pip3 install --upgrade pip==21.3.1 gunicorn==19.7.1 \
    && pip3 install -r /tmp/requirements-live.txt \
    && rm -r /root/.cache /tmp/requirements-live.txt

RUN npm config set unsafe-perm true
RUN npm install --global \
    @fortawesome/fontawesome-free@5.15.4 \
    acorn@6.4.2 \
    acorn-jsx@5.3.2 \
    acorn-dynamic-import@4.0.0 \
    bootstrap@4.4.1 \
    bufferutil@4.0.6 \
    font-awesome@4.7.0 \
    jquery@3.6.0 \
    jquery.noty.packaged.js@2.3.7 \
    lodash@4.17.21 \
    moment@2.29.1 \
    moment-timezone@0.5.34 \
    mustache@4.2.0 \
    noty@3.2.0-beta-deprecated \
    plotly.js@2.8.3 \
    popper.js@1.16.1 \
    selectize@0.12.6 \
    socket.io@2.3.0 \
    socket.io-client@2.3.0 \
    summernote@0.8.20 \
    tempusdominus-bootstrap-4@5.39.0 \
    tempusdominus-core@5.19.0 \
    utf-8-validate@5.0.8 \
    ws@7.2.1 

#RUN npm install --global @mapbox/mapbox-gl-style-spec @mapbox/mapbox-gl-supported plotly.js
# Live serves plotly 1.58.5. plotly-latest.min.js used to be that file but has since changed.
RUN mkdir -p /usr/lib/node_modules/plotly.js/dist &&  curl -L 'https://cdn.plot.ly/plotly-1.58.5.min.js' > /usr/lib/node_modules/plotly.js/dist/plotly.min.js

EXPOSE 8000

USER $GUNICORN_USER
ENTRYPOINT ["/entrypoint.sh"]
