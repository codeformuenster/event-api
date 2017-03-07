FROM python:3.6-alpine

RUN apk add --update \
  gcc python-dev musl-dev

RUN pip install \
  "elasticsearch~=5.1.0" \
  "certifi~=2017.1.23" \
  "connexion" \
  "gevent"

WORKDIR /scripts
COPY . /scripts
VOLUME /data
