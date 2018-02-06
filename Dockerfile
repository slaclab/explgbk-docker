FROM alpine

MAINTAINER Yee-Ting Li <yee379@gmail.com>

ENV APP_DIR /app
ENV GUNICORN_PORT=8000
ENV GUNICORN_USER=gunicorn

RUN apk add --no-cache bash git nginx uwsgi uwsgi-python python3 \
    && python3 -m ensurepip \
    && pip3 install --upgrade pip gunicorn \
    && adduser -D -h $APP_DIR $GUNICORN_USER
    
COPY entrypoint.sh /entrypoint.sh

WORKDIR ${APP_DIR}
COPY explgbk/ ${APP_DIR}/
ENV GUNICORN_MODULE=start
ENV GUNICORN_CALLABLE=app

RUN apk add --no-cache gcc libffi-dev python3-dev musl-dev openssl-dev
RUN pip3 install -r ${APP_DIR}/requirements.txt

RUN apk add --no-cache nodejs
RUN npm install --global jquery bootstrap@3.3.7 eonasdan-bootstrap-datetimepicker lodash moment mustache socket.io socket.io-client jquery.noty.packaged.js

RUN rm -r /root/.cache

EXPOSE 8000

USER $GUNICORN_USER
ENTRYPOINT ["/entrypoint.sh"]
