FROM python:3.6-alpine

RUN apk add --update \
  gcc python-dev musl-dev

RUN pip install \
  "elasticsearch~=5.2.0" \
  "certifi~=2017.1.23" \
  "connexion~=1.1.5" \
  "gevent~=1.2.1"

WORKDIR /scripts
COPY . /scripts
VOLUME /data
CMD ["python", "app.py"]
