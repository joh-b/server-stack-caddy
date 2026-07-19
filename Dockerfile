ARG CADDY_VERSION=2
ARG CADDY_CROWDSEC_BOUNCER_VERSION=0
ARG GO_LICENSES_VERSION=2.0.1

FROM docker.io/library/caddy:${CADDY_VERSION}-builder AS builder

ARG CADDY_CROWDSEC_BOUNCER_VERSION
ARG GO_LICENSES_VERSION

RUN set -eux; \
    XCADDY_SKIP_CLEANUP=1 xcaddy build \
        --with github.com/hslatman/caddy-crowdsec-bouncer@v${CADDY_CROWDSEC_BOUNCER_VERSION}; \
    GOBIN=/usr/local/bin go install github.com/google/go-licenses/v2@v${GO_LICENSES_VERSION}; \
    build_dir="$(find /tmp -maxdepth 1 -type d -name 'buildenv_*' -print -quit)"; \
    test -n "$build_dir"; \
    cd "$build_dir"; \
    go-licenses save \
        --save_path=/licenses \
        --ignore=caddy \
        --ignore=github.com/alecthomas/chroma/v2 \
        --ignore=github.com/hslatman/ipstore \
        .; \
    chroma_dir="$(go list -m -f '{{.Dir}}' github.com/alecthomas/chroma/v2)"; \
    ipstore_dir="$(go list -m -f '{{.Dir}}' github.com/hslatman/ipstore)"; \
    bouncer_dir="$(go list -m -f '{{.Dir}}' github.com/hslatman/caddy-crowdsec-bouncer)"; \
    mkdir -p \
        /licenses/github.com/alecthomas/chroma/v2 \
        /licenses/github.com/hslatman/ipstore \
        /licenses/golang.org/go; \
    cp "$chroma_dir/COPYING" /licenses/github.com/alecthomas/chroma/v2/COPYING; \
    cp "$bouncer_dir/LICENSE" /licenses/github.com/hslatman/ipstore/LICENSE; \
    sed -n '1,15p' "$ipstore_dir/ipstore.go" > /licenses/github.com/hslatman/ipstore/COPYRIGHT; \
    cp /usr/local/go/LICENSE /licenses/golang.org/go/LICENSE

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
COPY --from=builder /licenses /usr/share/licenses/server-stack-caddy

RUN setcap -v cap_net_bind_service=+ep /usr/bin/caddy

USER caddy
