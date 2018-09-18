FROM ubuntu:xenial

ARG ADMINPASS=insecure_to_be_changed_later
ARG PUBLIC_HOST=vpn.changeme.net

RUN apt-get update && apt-get -y upgrade && \
	apt-get install	-y lighttpd openvpn git nano less coreutils supervisor wget && \
	apt-get clean

COPY . /root
COPY supervisor/conf.d/* /etc/supervisor/conf.d/

WORKDIR /root

RUN bash openvpn.sh --adminpassword=$ADMINPASS --vpnport=1194 --protocol=tcp --host=$PUBLIC_HOST

EXPOSE 1194 443

CMD "/usr/bin/supervisord"


