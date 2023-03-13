#!/bin/bash
#
#INSTALLING GRAYLOG ON CENTOS STREAM 9
#Written by: Luis Fernández and Jose Hernández
#
#Last update: 09 of March of 2023
#
#
# -- ESTO ES IMPORTANTE -- POR FAVOR LEE CUIDADOSAMENTE
#
#
#
# -- La correcta forma de ejecutar el script es la siguiente:
# ./main-installer.sh [user_password] [username]
# donde [user_password] es la clave del usuario administrador del dashboard (ESTE DATO ES OBLIGATORIO)
# Y [username] es el usuario administrador, si no se especifica, el usuario sera el usuario default
#

PATH=$PATH:/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin

clustername="graylog" #Puede modificarse si se desea cambiar el nombre del cluster
root_password_sha2=$(echo -n $1 | sha256sum |awk '{print $1}')
firewall_active=$(systemctl --type=service --state=active |grep firewalld |wc -l)
firewall_inactive=$(systemctl --type=service --state=inactive |grep firewalld |wc -l)
opensearch_link=https://artifacts.opensearch.org/releases/bundle/opensearch/2.6.0/opensearch-2.6.0-linux-x64.rpm #Este es el URL del paquete RPM de opensearch 2.6.0, se puede cambiarse si se requiere otra versión
opensearch_rpm=opensearch-2.6.0-linux-x64.rpm #esta variable va de la mano con opensearch_link, ya que aca se especifica el nombre del paquete .rpm que se decarga del link antes mencionado, si se cambia opensearch_link, debe ajustarse esta variable al nombre del paquete que se instalara.

if [ -z $1 ];then
        echo "Necesitas pasar el parametro correspondiente para ejecutar correctamente el script. Para mayor información lee la documentación del script."
        exit
fi

dnf -y upgrade --refresh

dnf config-manager --set-enabled crb

dnf -y install \
    https://dl.fedoraproject.org/pub/epel/epel-release-latest-9.noarch.rpm \
    https://dl.fedoraproject.org/pub/epel/epel-next-release-latest-9.noarch.rpm \
    http://rpms.remirepo.net/enterprise/remi-release-9.rpm


#A continuación se configura el repositorio de mongodb 6.0 desde la página oficial, puede cambiarse si se requiere otra versión de mongodb

cat << EOF >> /etc/yum.repos.d/mongodb-org-6.0.repo
[mongodb-org-6.0]
name=MongoDB Repository
baseurl=https://repo.mongodb.org/yum/redhat/\$releasever/mongodb-org/6.0/x86_64/
gpgcheck=1
enabled=1
gpgkey=https://www.mongodb.org/static/pgp/server-6.0.asc
EOF

dnf -y update

dnf -y install wget vim policycoreutils-python-utils dnf-utils pwgen

password_secret=$(pwgen -N 1 -s 96)

wget -P /usr/local/src/ $opensearch_link

rpm -ivh /usr/local/src/$opensearch_rpm

rpm -Uvh https://packages.graylog2.org/repo/packages/graylog-5.0-repository_latest.rpm

dnf -y install mongodb-org graylog-server

if [ $firewall_active -eq $firewall_inactive ]; then
    dnf -y install firewalld
fi

echo "Description=Disable Transparent Huge Pages (THP)
DefaultDependencies=no
After=sysinit.target local-fs.target
[Service]
Type=oneshot
ExecStart=/bin/sh -c 'echo never | tee /sys/kernel/mm/transparent_hugepage/enabled > /dev/null'
[Install]
WantedBy=basic.target" | tee /etc/systemd/system/disable-transparent-huge-pages.service

cat << EOF >> /etc/opensearch/opensearch.yml
cluster.name: $clustername
action.auto_create_index: false
plugins.security.disabled: true
network.host: 0.0.0.0  
discovery.type: single-node
EOF

if [ "$2" ]; then
    sed -i "s/#root_username = admin/root_username = $2/g" /etc/graylog/server/server.conf
fi

sed -i "s/password_secret =/password_secret = $password_secret/g" /etc/graylog/server/server.conf
sed -i "s/root_password_sha2 =/root_password_sha2 = $root_password_sha2/g" /etc/graylog/server/server.conf
sed -i "s/#http_bind_address = 127.0.0.1:9000/http_bind_address = 0.0.0.0:9000/g" /etc/graylog/server/server.conf

systemctl daemon-reload

systemctl start disable-transparent-huge-pages.service
systemctl enable disable-transparent-huge-pages.service

systemctl start firewalld
systemctl enable firewalld

systemctl start mongod
systemctl enable mongod

systemctl start opensearch
systemctl enable opensearch

systemctl start graylog-server.service
systemctl enable graylog-server.service

firewall-cmd --add-port=9000/tcp --permanent
firewall-cmd --reload

setsebool -P httpd_can_network_connect 1
semanage port -a -t http_port_t -p tcp 9000
#semanage port -a -t http_port_t -p tcp 9200
#semanage port -a -t mongod_port_t -p tcp 27017