FROM alpine:latest AS builder

ARG TARGETARCH
ARG TARGETVARIANT

# default value if not provided
ARG DOWNLOAD_VERSION="latest"

# use musl build for alpine
# download_url="https://github.com/zhboner/realm/releases/download/$tag/realm-$arch-unknown-linux-musl.tar.gz"
ARG DOWNLOAD_REPO="https://github.com/zhboner/realm"
ARG DOWNLOAD_PREFIX="/releases/download/"

RUN apk upgrade --no-cache && \
    apk add --no-cache ca-certificates wget tar

# download
RUN RUN case "$TARGETARCH" in \
    amd64) ARCH_NAME="x86_64" ;; \
    arm64) ARCH_NAME="aarch64" ;; \
    arm) \
    case "$TARGETVARIANT" in \
    v7) ARCH_NAME="armv7" ;; \
    *)  ARCH_NAME="arm" ;; \
    esac ;; \
    *) ARCH_NAME="$TARGETARCH" ;; \
    esac && echo "Building for $ARCH_NAME" && \
    mkdir -p /tmp && cd /tmp && \
    wget ${DOWNLOAD_REPO}${DOWNLOAD_PREFIX}${DOWNLOAD_VERSION}/realm-${ARCH_NAME}-unknown-linux-musl.tar.gz && \
    tar -zxvf ./realm-${ARCH_NAME}-unknown-linux-musl.tar.gz && \
    chmod +x ./realm && mv ./realm /usr/bin/

FROM alpine:latest
COPY --from=builder /usr/bin/realm /usr/bin/realm

ENTRYPOINT ["/usr/bin/realm"]
