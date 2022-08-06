#!/bin/bash

/opt/steamcmd/steamcmd.sh +quit
/opt/steamcmd/steamcmd.sh +login anonymous +force_install_dir /data/avorion +app_update 565060 validate +quit

/data/avorion/server.sh --use-steam-networking 1 --galaxy-name $GALAXY_NAME --admin $SERVER_ADMIN --datapath /data/save
