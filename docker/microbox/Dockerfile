# @version
FROM ghcr.io/sagernet/sing-box:v1.13.12 AS dumper

FROM ghcr.io/se1jaku/supervisor:latest

COPY --from=dumper /usr/local/bin/ /usr/local/bin/

RUN apk upgrade --no-cache \
    && apk add --no-cache nftables bind-tools iproute2 \
    && mkdir -p /etc/sing-box /var/lib/sing-box

COPY bin/ /usr/local/bin/
COPY etc/ /etc/
COPY res/ /res/

ENV SINGBOX_REMOTE_URL=
ENV SINGBOX_CONFIG_DIR=/etc/sing-box
ENV SINGBOX_DATA_DIR=/var/lib/sing-box

ENTRYPOINT ["entrypoint.sh"]
CMD ["supervisord", "-c", "/etc/supervisord.conf"]
