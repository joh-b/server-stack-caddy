ARG CADDY_VERSION=2
ARG CADDY_CROWDSEC_BOUNCER_VERSION=0

FROM docker.io/library/caddy:${CADDY_VERSION}-builder AS builder

ARG CADDY_CROWDSEC_BOUNCER_VERSION

RUN xcaddy build \
    --with github.com/hslatman/caddy-crowdsec-bouncer@v${CADDY_CROWDSEC_BOUNCER_VERSION}

FROM docker.io/library/caddy:${CADDY_VERSION}

ARG CADDY_UID=10001
ARG CADDY_GID=10001

USER root

RUN set -eux; \
    addgroup -S -g "${CADDY_GID}" caddy; \
    adduser -S -D -H -h /var/lib/caddy -s /sbin/nologin -G caddy -u "${CADDY_UID}" caddy; \
    mkdir -p /data/caddy /config/caddy /var/log/caddy; \
    chown -R caddy:caddy /data /config /var/log/caddy

COPY --from=builder /usr/bin/caddy /usr/bin/caddy

RUN setcap -v cap_net_bind_service=+ep /usr/bin/caddy

USER caddy
