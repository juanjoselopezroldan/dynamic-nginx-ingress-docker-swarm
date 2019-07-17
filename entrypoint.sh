#!/bin/bash

echo "y" | ssh-keygen -t rsa -N "" -f /root/.ssh/id_rsa
cat /root/.ssh/id_rsa.pub >> /root/.ssh/authorized_keys
echo " " > /etc/nginx/conf.d/default.conf
finish="1"

for ip in $IP_NODES
do
        echo $ip
        echo "yes" | ssh -o "StrictHostKeyChecking no" -o "PasswordAuthentication=no" $USER_ACCESS_SSH@$ip -i /root/.ssh/id_rsa exit
        check=$(echo $?)
        if [[ $check == "0" && $finish == "1" ]] ;
        then
                services=$(docker -H ssh://$USER_ACCESS_SSH@$ip service ls --format "{{.Name}}" | grep -v $NAME_SERVICE)
                for service in $services
                do
                        echo $service
                        service_details=$(docker -H ssh://$USER_ACCESS_SSH@$ip service inspect $service)
                        ip_service=$(echo $service_details | jq -r '.[].Endpoint.VirtualIPs[].Addr' | cut -d "/" -f 1)
                        echo $ip_service
                        domain=$(echo $service_details | jq -r '.[].Spec.Labels.domain')
                        port_app=$(echo $service_details | jq -r '.[].Spec.Labels.port_app')
                        echo $domain
                        echo $port_app

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
                        sleep 1
                done
	        nginx -t
        	nginx -c /etc/nginx/nginx.conf
                export KEY_NO_VALID=$(grep "$(cat /root/.ssh/id_rsa.pub)" -v /root/.ssh/authorized_keys) | echo $KEY_NO_VALID > /root/.ssh/authorized_keys
                finish="0"
        fi
done
