FROM debian:13.1

ENV DEBIAN_FRONTEND=noninteractive

ARG TARGETARCH

ARG DOWNLOAD_HOST="https://dl.nyafw.com"
ARG DOWNLOAD_PREFIX="/download/"

RUN apt-get update && \
    apt-get install -y tzdata ca-certificates wget curl && \
    apt-get clean && \
    mkdir -p /root/.config

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

ENV IPV4_PRECEDENCE=1

ENTRYPOINT ["entrypoint.sh"]
