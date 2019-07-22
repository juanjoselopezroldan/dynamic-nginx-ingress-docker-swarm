# dynamic-nginx-ingress-docker-swarm
In this repository is the code that allows the deployment of a dynamic nginx ingress for docker swarm, for to expose a service of reverse proxy that swing the request to the rest of services of cluster of docker swarm.

This proxy is configurated automatically for a script of entrypoint, also if in the cluster deploy new services, this nginx added the services new automatically.

For they in the deploy of service, we have to indicate the name of domain, the port to use and if we want add to nginx ingress and all the is do throug of labels indicated in the service and they are the following
 ```
label -> 'ingress=yes'
label -> 'domain=apache-test.com'
label -> 'port_app=80'
 ```

For deploy a environment of test and so check the operation correct of this ingress, we will use with two networks, one for nginx ingress and the second for the services that we want use.

![Alt Text](/image/nginx_ingress.png)

First, we have to create the networks for the operation correct of nginx ingress.

```
docker network create -d overlay --attachable internal
docker network create -d overlay --subnet=10.11.0.0/16 --gateway=10.11.0.2 nginx
```

We deploy the services that we will want to use, in our case we going to deploy two services web how try.

Service web with Apache.
```
docker service create --replicas 2 --name servidor_web -l 'ingress=yes' -l 'domain=apache-test.com' -l 'port_app=80' --network internal httpd
```

Service web with Nginx.
```
docker service create --replicas 2 --name servidor_web_nginx -l 'ingress=yes' -l 'domain=nginx-test.com' -l 'port_app=80' --network internal nginx

```

For to finish, we deploy the service nginx ingress and we indicating the next parameters:

```
docker service create --name nginx_ingress --mount type=bind,src=/root/.ssh/authorized_keys,dst=/root/.ssh/authorized_keys --network nginx --network internal --env IP_NODES="10.40.10.71 10.40.10.72" --env USER_ACCESS_SSH="root" --env NAME_SERVICE="nginx_ingress" -p 80:80 juanjoselo/dynamic-nginx-ingress-docker-swarm:latest
```

- --mount type=bind,src=/root/.ssh/authorized_keys,dst=/root/.ssh/authorized_keys -> We indicate how point mount the file authorized_keys for that the service can write and indicate your public key for it can do request the cluster of docker and get the information need.
- --network nginx --network internal -> We indicate the two networks that we go to use (the first for to expose the ningx ingress and the second for that the services connect with nginx).
- --env IP_NODES="10.40.10.71 10.40.10.72" -> We indicate the enviroment variables that use our image of nginx, being in this case the direcctions ip of all nodes of cluster of docker swarm for that the service try the connection whit the nodes and it can to connect with the node in the that be.
- --env USER_ACCESS_SSH="root" -> We indicate the user that use for connect with the node for to get the information need.
- --env NAME_SERVICE="nginx_ingress" -> We indicate the name that we to assign of service for that in the search of rest services of cluster, this the ignore and it not to add to reverse proxy
- -p 80:80 -> Also we indicate the port that we go to expose for that we can connecto from outside of network