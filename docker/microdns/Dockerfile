# @version
FROM pymumu/smartdns:Release48 AS dumper

FROM ghcr.io/se1jaku/supervisor:latest

COPY --from=dumper /usr/local/lib/smartdns /usr/local/lib/smartdns

RUN ln -s /usr/local/lib/smartdns/run-smartdns /usr/local/bin/smartdns \
    && mkdir -p /etc/smartdns

COPY bin/ /usr/local/bin/
COPY etc/ /etc/
COPY res/ /res/
COPY enc/ /enc/

ENTRYPOINT ["entrypoint.sh"]
