FROM nginx:1.17.1

ENV IP_NODES="10.40.10.71 10.40.10.72" \
	USER_ACCESS_SSH="root" \
	NAME_SERVICE="nginx_ingress"

ARG VERSION_DOCKER=18.09.7
ARG DIRECTORY_SSH_NODE=/root/.ssh

RUN apt update \
	&& apt install -y \
	jq \
	nano \
	wget \
	ssh \
	&& mkdir -p /entrypoint

ADD entrypoint.sh /entrypoint/entrypoint.sh

RUN cd /tmp \
	&& wget https://download.docker.com/linux/static/stable/x86_64/docker-$VERSION_DOCKER.tgz \
	&& tar xzvf docker-$VERSION_DOCKER.tgz \
	&& cp -R docker/* /usr/bin/ \
	&& mkdir -p /root/.ssh/ \
	&& chmod +x /entrypoint/entrypoint.sh


VOLUME $DIRECTORY_SSH_NODE/authorized_keys /root/.ssh/authorized_keys
CMD ["/bin/bash", "/entrypoint/entrypoint.sh"]
