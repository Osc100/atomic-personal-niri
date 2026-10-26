# Each script gets a stage of its own: a step is rebuilt when what it mounts
# changes, so a config edit doesn't redo the package installs.
FROM scratch AS packages
COPY build_files/packages.sh /

FROM scratch AS setup
COPY build_files/setup.sh /

FROM ghcr.io/ublue-os/base-main:beta

RUN --mount=type=bind,from=packages,source=/,target=/ctx \
    --mount=type=cache,dst=/var/cache \
    --mount=type=cache,dst=/var/log \
    --mount=type=tmpfs,dst=/tmp \
    /ctx/packages.sh

COPY system_files /

RUN --mount=type=bind,from=setup,source=/,target=/ctx \
    --mount=type=tmpfs,dst=/tmp \
    /ctx/setup.sh

RUN bootc container lint
