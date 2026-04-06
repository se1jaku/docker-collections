# @version
FROM ghcr.io/se1jaku/realm:v2.9.3

RUN apk upgrade --no-cache && \
    apk add --no-cache bash iproute2 mptcpize

ENV MPTCP_DIRECTION=

ENTRYPOINT ["entrypoint.sh"]
CMD ["-c", "/etc/realm/config.yml"]
