FROM alpine:latest

ARG TARGETARCH

ARG DOWNLOAD_HOST="https://dl.nyafw.com"
ARG DOWNLOAD_PREFIX="/download/"

RUN apk upgrade --no-cache && \
    apk add --no-cache bash tzdata ca-certificates wget curl

# download
RUN mkdir -p /opt/nodeclient && cd /opt/nodeclient && \
    wget ${DOWNLOAD_HOST}${DOWNLOAD_PREFIX}download.sh && \
    bash download.sh ${DOWNLOAD_HOST} rel_nodeclient_linux_${TARGETARCH};

# download v3 for amd64
RUN if [ "$TARGETARCH" = "amd64" ]; then \
    mkdir -p /opt/nodeclientv3 && cd /opt/nodeclientv3 && \
    wget ${DOWNLOAD_HOST}${DOWNLOAD_PREFIX}download.sh && \
    bash download.sh ${DOWNLOAD_HOST} rel_nodeclient_linux_amd64v3; \
    fi

COPY entrypoint.sh /usr/local/bin/

ENTRYPOINT ["entrypoint.sh"]
