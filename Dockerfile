#FROM node:8.10.0-alpine
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

RUN python3 -m ensurepip \
    && pip3 install --upgrade pip gunicorn \
    && pip3 install -r ${APP_DIR}/requirements.txt \
    && rm -r /root/.cache

RUN npm config set unsafe-perm true
RUN npm install --global \
    @fortawesome/fontawesome-free \
    acorn@^6.0.0 \
    acorn-jsx \
    acorn-dynamic-import \
    bootstrap@4.4.1 \
    bufferutil@^4.0.1 \
    font-awesome \
    jquery \
    jquery.noty.packaged.js \
    lodash \
    moment \
    moment-timezone \
    mustache \
    noty \
    plotly.js \
    popper.js \
    selectize \
    socket.io@2.3.0 \
    socket.io-client@2.3.0 \
    summernote \
    tempusdominus-bootstrap-4 \
    tempusdominus-core \
    utf-8-validate@^5.0.2 \
    ws@7.2.1 

#RUN npm install --global @mapbox/mapbox-gl-style-spec @mapbox/mapbox-gl-supported plotly.js
RUN mkdir -p /usr/lib/node_modules/plotly.js/dist &&  curl -L 'https://cdn.plot.ly/plotly-latest.min.js' > /usr/lib/node_modules/plotly.js/dist/plotly.min.js

EXPOSE 8000

USER $GUNICORN_USER
ENTRYPOINT ["/entrypoint.sh"]
