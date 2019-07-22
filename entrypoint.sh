#!/bin/bash
#set -x
echo "y" | ssh-keygen -t rsa -N "" -f /root/.ssh/id_rsa
cat /root/.ssh/id_rsa.pub >> /root/.ssh/authorized_keys
finish="1"
check="True"

configuration_nginx () {
services=$(docker -H ssh://$1@$2 service ls --format "{{.Name}}" | grep -v $3)
number_services=$(echo "$services" | wc -l)
echo "" > /etc/nginx/conf.d/default.conf
for service in $services
do
        service_details=$(docker -H ssh://$USER_ACCESS_SSH@$ip service inspect $service)
        ingress=$(echo $service_details | jq -r '.[].Spec.Labels.ingress'|  awk '{print tolower($0)}')
        echo $ingress
        echo " / Name service: $service"
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

for ip in $IP_NODES
do
        echo "Checking connection with the direction $ip"
        echo "yes" | ssh -o "StrictHostKeyChecking no" -o "PasswordAuthentication=no" $USER_ACCESS_SSH@$ip -i /root/.ssh/id_rsa exit
        check=$(echo $?)
        if [[ $check == "0" && $finish == "1" ]] ;
        then
                echo "Connection successfully 😀"
                echo "Generating file of configuration for nginx"
                configuration_nginx $USER_ACCESS_SSH $ip $NAME_SERVICE
                nginx -t
                echo "Starting service of nginx"
                nginx -g "daemon off;" &
                while [[ $check ]]; do
                        check_services=$(docker -H ssh://$USER_ACCESS_SSH@$ip service ls --format "{{.Name}}" | grep -v $NAME_SERVICE | wc -l)
                        if [[ "$check_services" != "$number_services" ]]; then
                                echo "Exist changes in the services, generating new file of configuration..."
                                configuration_nginx $USER_ACCESS_SSH $ip $NAME_SERVICE
                                echo "Restarting configuration of nginx"
                                nginx -s reload
                        fi
                        sleep 60
                done
                export KEY_NO_VALID=$(grep "$(cat /root/.ssh/id_rsa.pub)" -v /root/.ssh/authorized_keys) | echo $KEY_NO_VALID > /root/.ssh/authorized_keys
                finish="0"
        else
                echo "Connection failed"
        fi
done
