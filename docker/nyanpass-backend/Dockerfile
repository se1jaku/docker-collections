FROM debian:12.12

ENV DEBIAN_FRONTEND=noninteractive

ARG TARGETARCH

ARG DOWNLOAD_HOST="https://dl.nyafw.com"
ARG DOWNLOAD_PREFIX="/download/"

RUN apt-get update && \
    apt-get install -y tzdata ca-certificates iputils-ping wget curl && \
    apt-get clean

# download
RUN mkdir -p /opt/backend && cd /opt/backend && \
    wget ${DOWNLOAD_HOST}${DOWNLOAD_PREFIX}download.sh && \
    bash download.sh ${DOWNLOAD_HOST} rel_backend_linux_${TARGETARCH};

COPY entrypoint.sh /usr/local/bin/

ENTRYPOINT ["entrypoint.sh"]
