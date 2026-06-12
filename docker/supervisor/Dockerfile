# @version
FROM python:3-alpine

ENV TZ=Etc/UTC

RUN apk upgrade --no-cache \
    && apk add --no-cache bash expect tzdata ca-certificates wget curl jq rage \
    && pip install supervisor pexpect requests jinja2 \
    && mkdir -p /res /enc

COPY bin/ /usr/local/bin/
COPY etc/ /etc/

ENV RESOURCE_BASE_URL=https://raw.githubusercontent.com/se1jaku/docker-collections/main

ENTRYPOINT ["entrypoint.sh"]
CMD ["supervisord", "-c", "/etc/supervisord.conf"]
