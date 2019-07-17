SHELL := /bin/bash

build:
	docker build -f Dockerfile -t juanjoselo/dynamic-nginx-ingress-docker-swarm:latest .

build-no-cache:
	docker build -f Dockerfile --no-cache -t juanjoselo/dynamic-nginx-ingress-docker-swarm:latest .

push:
	docker push juanjoselo/dynamic-nginx-ingress-docker-swarm:latest

