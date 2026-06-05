# @version
FROM ghcr.io/sagernet/sing-box:v1.13.12 AS dumper

FROM alpine:latest

ENV TZ=Etc/UTC

RUN apk upgrade --no-cache \
    && apk add --no-cache bash tzdata ca-certificates nftables \
    curl jq bind-tools iproute2 supervisor \
    && ln -snf /usr/share/zoneinfo/$TZ /etc/localtime \
    && echo $TZ > /etc/timezone

COPY --from=dumper /usr/local/bin/* /usr/local/bin
COPY bin/ /usr/local/bin/
COPY entrypoint.sh /usr/local/bin/
COPY service.ini /etc/supervisor.d/

ENV BACKUP_DIR=/backup
ENV REPOSITORY_URL=https://raw.githubusercontent.com/se1jaku/docker-collections/main

ENV SINGBOX_REMOTE_URL=
ENV SINGBOX_CONFIG_DIR=/etc/sing-box
ENV SINGBOX_DATA_DIR=/var/lib/sing-box

ENTRYPOINT ["entrypoint.sh"]
CMD ["supervisord", "-c", "/etc/supervisord.conf"]
