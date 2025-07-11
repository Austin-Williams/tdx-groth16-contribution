# Thin wrapper that ships Docker CLI + Buildx plugin and talks to the host daemon.
FROM stagex/core-busybox@sha256:cac5d773db1c69b832d022c469ccf5f52daf223b91166e6866d42d6983a3b374 AS base

ENV SOURCE_DATE_EPOCH=1 TZ=UTC LANG=C.UTF-8

USER 0

COPY --from=stagex/core-ca-certificates@sha256:d6fca6c0080e8e5360cd85fc1c4bd3eab71ce626f40602e38488bfd61fd3e89d / /
COPY --from=stagex/core-musl@sha256:d5f86324920cfc7fc34f0163502784b73161543ba0a312030a3ddff3ef8ab2f8 /usr/lib /usr/lib
COPY --from=stagex/user-docker@sha256:81b771e703ec4a1ee532c3bb8718032325fe1084306e8909840cfde990e6b1c1 /usr/bin/docker /usr/bin/docker
COPY --from=stagex/user-docker@sha256:81b771e703ec4a1ee532c3bb8718032325fe1084306e8909840cfde990e6b1c1 /usr/bin/docker-proxy /usr/bin/docker-proxy
COPY --from=stagex/user-docker-cli-buildx@sha256:6c3147b342f68d10023dfa4dd80d5e12a986cc37ab7b00d97398935cd47288a7 /usr/libexec/docker/cli-plugins/ /usr/libexec/docker/cli-plugins/

WORKDIR /work
ENTRYPOINT ["/usr/bin/docker"]