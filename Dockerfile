FROM ghcr.io/f0rkz/docker-steamcmd:latest
LABEL maintainer="f0rkz@f0rkznet.net"

# SERVER_ADMIN is steamid64 value for first admin
# https://www.steamidfinder.com/
ENV SERVER_ADMIN 0

# Galaxy name is the
ENV GALAXY_NAME galaxy

VOLUME /data

EXPOSE 27000 27000/udp
EXPOSE 27003 27003/udp
EXPOSE 27020 27020/udp
EXPOSE 27021 27020/udp

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

CMD /entrypoint.sh