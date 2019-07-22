FROM nginx:1.17.1

ENV NAME_SERVICE="nginx_ingress"

ARG VERSION_DOCKER=18.09.7

RUN apt update \
	&& apt install -y \
	jq \
	nano \
	wget \
	&& mkdir -p /entrypoint

ADD entrypoint.sh /entrypoint/entrypoint.sh

RUN cd /tmp \
	&& wget https://download.docker.com/linux/static/stable/x86_64/docker-$VERSION_DOCKER.tgz \
	&& tar xzvf docker-$VERSION_DOCKER.tgz \
	&& cp -R docker/* /usr/bin/ \
	&& mkdir -p /root/.ssh/ \
	&& chmod +x /entrypoint/entrypoint.sh


VOLUME /var/run/docker.sock /var/run/docker.sock
CMD ["/bin/bash", "/entrypoint/entrypoint.sh"]
