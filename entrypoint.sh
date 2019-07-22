#!/bin/bash
#set -x
check="True"

#Function for to generate the file of configuration of the services of cluster of docker doing request to the API of docker and get the information with the command inspect and check the labels of services
configuration_nginx () {
services=$(docker service ls --format "{{.Name}}" | grep -v $1)
number_services=$(echo "$services" | wc -l)
echo "" > /etc/nginx/conf.d/default.conf
for service in $services
do
        service_details=$(docker service inspect $service)
        ingress=$(echo $service_details | jq -r '.[].Spec.Labels.ingress'|  awk '{print tolower($0)}')
        echo " / Name service: $service"
        #If the service is not have the label ingress in yes, it not add the service to nginx
        if [[ $ingress == "yes" ]]; then
                ip_service=$(echo $service_details | jq -r '.[].Endpoint.VirtualIPs[].Addr' | cut -d "/" -f 1)
                domain=$(echo $service_details | jq -r '.[].Spec.Labels.domain')
                port_app=$(echo $service_details | jq -r '.[].Spec.Labels.port_app')

                echo "|  Direcction ip of service: $ip_service"
                echo "|  Domain of service: $domain"
                echo " \ Port of service: $port_app"

                cat <<-EOF >> /etc/nginx/conf.d/default.conf
                upstream $service-$domain {
                        server $ip_service:$port_app;
                }
                server {
                        listen       80;
                        server_name $domain;
                        client_body_timeout 15s;
                        client_header_timeout 15s;

                        location / {
                                proxy_pass http://$ip_service/;
                                }
                        }
EOF
        else
                echo " \ Service \"$service\" not added because it does not have ingress tag defined in yes"
        fi
        sleep 1
done
}

echo "Init of entrypoint"
echo "Generating file of configuration for nginx"
configuration_nginx $NAME_SERVICE
#when to finis the configuration of nginx, check that the configuration is correct and start the service of nginx
nginx -t
echo "Starting service of nginx 😀"
nginx -g "daemon off;" &
#When already is in execution the service of nginx, every 60 seconds to check if there is new services deployed
while [[ $check ]]; do
        check_services=$(docker service ls --format "{{.Name}}" | grep -v $NAME_SERVICE | wc -l)
        if [[ "$check_services" != "$number_services" ]]; then
                echo "Exist changes in the services, generating new file of configuration..."
                configuration_nginx $NAME_SERVICE
                echo "Restarting configuration of nginx 😀"
                nginx -s reload
        fi
        sleep 60
done
