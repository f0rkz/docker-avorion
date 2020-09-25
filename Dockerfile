FROM ubuntu:latest
LABEL maintainer="f0rkz@f0rkznet.net"

ENV SERVER_ADMIN 0
ENV GALAXY_NAME galaxy

RUN apt-get update -yq && apt-get -yq install wget lib32gcc1 tar

RUN wget "https://steamcdn-a.akamaihd.net/client/installer/steamcmd_linux.tar.gz" -O /tmp/steamcmd_linux.tar.gz
RUN mkdir -p /opt/steamcmd && tar zxfv /tmp/steamcmd_linux.tar.gz -C /opt/steamcmd
RUN rm -r /tmp/steamcmd_linux.tar.gz

RUN mkdir -p /opt/avorion
RUN /opt/steamcmd/steamcmd.sh +quit
RUN /opt/steamcmd/steamcmd.sh \
    +login anonymous \
	+force_install_dir /opt/avorion \
	+app_update 565060 validate \
	+quit

RUN cp /opt/steamcmd/linux64/steamclient.so /opt/avorion/

VOLUME /data

EXPOSE 27000 27000/udp
EXPOSE 27003 27003/udp
EXPOSE 27020 27020/udp
EXPOSE 27021 27020/udp

CMD /opt/avorion/server.sh --use-steam-networking 1 --galaxy-name $GALAXY_NAME --admin $SERVER_ADMIN --datapath /data
