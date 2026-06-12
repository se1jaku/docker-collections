# @version
FROM pymumu/smartdns:Release48 AS dumper

FROM python:3-alpine

ENV TZ=Etc/UTC

COPY --from=dumper /usr/local/lib/smartdns /usr/local/lib/smartdns

RUN apk upgrade --no-cache \
    && apk add --no-cache bash expect tzdata ca-certificates wget curl jq rage \
    && pip install supervisor pexpect requests jinja2 \
    && ln -snf /usr/share/zoneinfo/$TZ /etc/localtime \
    && ln -s /usr/local/lib/smartdns/run-smartdns /usr/local/bin/smartdns \
    && echo $TZ > /etc/timezone \
    && mkdir -p /res /enc /etc/smartdns

COPY bin/ /usr/local/bin/
COPY etc/ /etc/
COPY res/ /res/
COPY enc/ /enc/

ENV RAGE_PASSPHRASE=
ENV RESOURCE_BASE_URL=https://raw.githubusercontent.com/se1jaku/docker-collections/main

ENTRYPOINT ["entrypoint.sh"]
CMD ["supervisord", "-c", "/etc/supervisord.conf"]
