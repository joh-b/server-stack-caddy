ARG CADDY_VERSION=2.11

FROM docker.io/library/caddy:${CADDY_VERSION}-builder AS builder
RUN xcaddy build \
    --with github.com/hslatman/caddy-crowdsec-bouncer/http

FROM docker.io/library/caddy:${CADDY_VERSION}
USER root
COPY --from=builder /usr/bin/caddy /usr/bin/caddy
RUN setcap -v cap_net_bind_service=+ep /usr/bin/caddy
USER caddy
