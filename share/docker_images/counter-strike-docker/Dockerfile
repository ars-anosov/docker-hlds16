FROM debian:jessie

RUN dpkg --add-architecture i386
RUN apt update && apt install -y lib32gcc1 curl locales libsdl2-2.0-0:i386 unzip

# locale
RUN localedef -f UTF-8 -i en_US en_US.UTF-8

# Install SteamCMD
RUN mkdir -p /opt/steam && cd /opt/steam && \
    curl -sqL "https://steamcdn-a.akamaihd.net/client/installer/steamcmd_linux.tar.gz" | tar zxvf -


# Install HLDS
ARG steam_user=USER_HERE
ARG steam_password=PASSWORD_HERE
ARG steam_guard=
ARG metamod_version=1.20
ARG amxmod_version=1.8.2

RUN mkdir -p /opt/hlds
# Workaround for "app_update 90" bug, see https://forums.alliedmods.net/showthread.php?p=2518786
RUN /opt/steam/steamcmd.sh +login $steam_user $steam_password $steam_guard +force_install_dir /opt/hlds +app_update 90 validate +quit || true
RUN /opt/steam/steamcmd.sh +login $steam_user $steam_password $steam_guard +force_install_dir /opt/hlds +app_update 70 validate +quit || true
RUN /opt/steam/steamcmd.sh +login $steam_user $steam_password $steam_guard +force_install_dir /opt/hlds +app_update 10 validate +quit || true
RUN /opt/steam/steamcmd.sh +login $steam_user $steam_password $steam_guard +force_install_dir /opt/hlds +app_update 90 validate +quit
RUN mkdir -p ~/.steam && ln -s /opt/hlds ~/.steam/sdk32
RUN ln -s /opt/steam/ /opt/hlds/steamcmd
ADD files/steam_appid.txt /opt/hlds/steam_appid.txt
ADD hlds_run.sh /bin/hlds_run.sh
RUN chmod +x /bin/hlds_run.sh

# Add default config
ADD files/server.cfg /opt/hlds/cstrike/server.cfg

# Add maps
ADD maps/* /opt/hlds/cstrike/maps/
ADD files/mapcycle.txt /opt/hlds/cstrike/mapcycle.txt

# Install metamod
RUN mkdir -p /opt/hlds/cstrike/addons/metamod/dlls
#RUN curl -sqL "http://prdownloads.sourceforge.net/metamod/metamod-$metamod_version-linux.tar.gz?download" | tar -C /opt/hlds/cstrike/addons/metamod/dlls -zxvf -
RUN curl -sqL -o metamod-1.21.1-am.zip "https://www.amxmodx.org/release/metamod-1.21.1-am.zip" && unzip -d /opt/hlds/cstrike metamod-1.21.1-am.zip
ADD files/liblist.gam /opt/hlds/cstrike/liblist.gam
# Remove this line if you aren't going to install/use amxmodx and dproto
ADD files/plugins.ini /opt/hlds/cstrike/addons/metamod/plugins.ini

# Install dproto
RUN mkdir -p /opt/hlds/cstrike/addons/dproto
ADD files/dproto_i386.so /opt/hlds/cstrike/addons/dproto/dproto_i386.so
ADD files/dproto.cfg /opt/hlds/cstrike/dproto.cfg

# Install AMX mod X
#RUN curl -sqL "http://www.amxmodx.org/release/amxmodx-$amxmod_version-base-linux.tar.gz" | tar -C /opt/hlds/cstrike/ -zxvf -
RUN curl -sqL -o amxmodx-1.9.0-git5292-base-linux.tar.gz "https://www.amxmodx.org/amxxdrop/1.9/amxmodx-1.9.0-git5292-base-linux.tar.gz" && tar -C /opt/hlds/cstrike/ -zxvf amxmodx-1.9.0-git5292-base-linux.tar.gz
#RUN curl -sqL "http://www.amxmodx.org/release/amxmodx-$amxmod_version-cstrike-linux.tar.gz" | tar -C /opt/hlds/cstrike/ -zxvf -
RUN curl -sqL -o amxmodx-1.9.0-git5292-cstrike-linux.tar.gz "https://www.amxmodx.org/amxxdrop/1.9/amxmodx-1.9.0-git5292-cstrike-linux.tar.gz" && tar -C /opt/hlds/cstrike/ -zxvf amxmodx-1.9.0-git5292-cstrike-linux.tar.gz
ADD files/maps.ini /opt/hlds/cstrike/addons/amxmodx/configs/maps.ini

#RUN chmod 755 /opt/hlds/cstrike/addons
#RUN chmod 755 /opt/hlds/cstrike/addons/amxmodx

# Cleanup
RUN apt remove -y curl

WORKDIR /opt/hlds

ENTRYPOINT ["/bin/hlds_run.sh"]
