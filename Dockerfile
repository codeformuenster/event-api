FROM python:3.6-alpine

RUN apk --no-cache add --virtual .build-deps \
    gcc python-dev musl-dev \
  && pip install \
    "elasticsearch~=5.2.0" \
    "certifi~=2017.1.23" \
    "connexion~=1.1.5" \
    "gevent~=1.2.1" \
  && apk del .build-deps

WORKDIR /usr/src/app
COPY ./connexion /usr/src/app

CMD ["python", "app.py"]
