FROM debian:12.12

ENV DEBIAN_FRONTEND=noninteractive

ARG TARGETARCH

ARG DOWNLOAD_HOST="https://dl.nyafw.com"
ARG DOWNLOAD_PREFIX="/download/"
ARG PRODUCT="rel_backend"

RUN apt-get update && \
    apt-get install -y tzdata ca-certificates iputils-ping wget curl && \
    apt-get clean

# download
RUN mkdir -p /opt/backend && cd /opt/backend && \
    wget ${DOWNLOAD_HOST}${DOWNLOAD_PREFIX}download.sh && \
    bash download.sh ${DOWNLOAD_HOST} ${PRODUCT}_linux_${TARGETARCH};

# download v3 for amd64
RUN if [ "$TARGETARCH" = "amd64" ]; then \
    mkdir -p /opt/backendv3 && cd /opt/backendv3 && \
    wget ${DOWNLOAD_HOST}${DOWNLOAD_PREFIX}download.sh && \
    bash download.sh ${DOWNLOAD_HOST} ${PRODUCT}_linux_amd64v3; \
    fi

COPY entrypoint.sh /usr/local/bin/

ENV IPV4_PRECEDENCE=1

ENTRYPOINT ["entrypoint.sh"]
