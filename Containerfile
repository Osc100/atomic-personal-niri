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

# claude-devin-acp, Devin for OpenCode: a release of its own repository, checked
# against its checksum (SHA256SUMS in the release). A new version is a new URL
# and checksum here.
ADD --chmod=0755 \
    --checksum=sha256:8d6692f2b6e62a7b55021be86f42a0b6bba968679408934cfcdbfdd3fa14bdb9 \
    https://github.com/Osc100/claude-devin-acp/releases/download/v0.1.0/claude-devin-acp-linux-amd64 \
    /usr/bin/claude-devin-acp

RUN --mount=type=bind,from=setup,source=/,target=/ctx \
    --mount=type=tmpfs,dst=/tmp \
    /ctx/setup.sh

RUN bootc container lint
