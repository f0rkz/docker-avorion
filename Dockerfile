# syntax=docker/dockerfile:1

ARG STEAMCMD_IMAGE=ghcr.io/f0rkz/docker-steamcmd:2
FROM ${STEAMCMD_IMAGE}

LABEL org.opencontainers.image.title="Avorion Dedicated Server" \
      org.opencontainers.image.description="Avorion dedicated server powered by SteamCMD" \
      org.opencontainers.image.source="https://github.com/f0rkz/docker-avorion"

ENV AVORION_DATA_PATH=/data/save \
    AVORION_INSTALL_DIR=/data/avorion \
    AVORION_USER_DIR=/data/home \
    ALLOWED_CLIENT_MODS="" \
    FORCE_ENABLE_MODS=false \
    GALAXY_NAME="" \
    SERVER_ADMIN=0 \
    STEAMCMD_RETRIES=3 \
    STEAMCMD_VALIDATE=false \
    WORKSHOP_MODS=""

COPY --chown=steam:steam entrypoint.sh /usr/local/bin/avorion-entrypoint

EXPOSE 27000/tcp 27000/udp \
       27003/tcp 27003/udp \
       27020/tcp 27020/udp \
       27021/tcp 27021/udp

STOPSIGNAL SIGINT

ENTRYPOINT ["/usr/local/bin/avorion-entrypoint"]
