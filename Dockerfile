FROM python:3.6-alpine

RUN apk --no-cache add tini \
  && apk --no-cache add --virtual .build-deps \
    gcc python-dev musl-dev \
  && pip install \
    "elasticsearch~=5.3.0" \
    "certifi~=2017.4.17" \
    "connexion~=1.1.9" \
    "gevent~=1.2.1" \
    "flask-cors~=3.0.2" \
  && apk del .build-deps

WORKDIR /usr/src/app
COPY . /usr/src/app

CMD ["/sbin/tini", "--", "python", "resty.py"]
