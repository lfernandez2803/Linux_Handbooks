#!/bin/bash
#
#INSTALLING OSTICKET V1.15.4 ON CENTOS 8
#Written by: Luis Fernández
#EMAIL: lfernandez2803 AT gmail dot com
#Last update: 26 of October of 2021
#
#TO READ
#You must change the value of the variables according your configuration
#
#

PATH=$PATH:/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin

DOWNLOAD_LINK="https://github.com/osTicket/osTicket.git"
CURRENT_MYSQL_PASSWORD=' '
NEW_MYSQL_PASSWORD='strongpassword'     #Must be change
NEW_DB_USER='zabbix'                    #Must be change
NEW_DB_PASSWORD='AnotherStrongPassword' #Must be change
NEW_DB='zabbix'                         #Must be change


dnf -y update
dnf -y install \
https://dl.fedoraproject.org/pub/epel/epel-release-latest-8.noarch.rpm \
https://rpms.remirepo.net/enterprise/remi-release-8.rpm

dnf -y update

dnf -y install \
yum-utils  \
wget \
unzip \
curl \
htop \
vim \
curl \
git \
expect

dnf -y install \
php \
php-{pear,\
cgi,\
common,\
curl,\
mbstring,\
gd,\
mysqlnd,\
gettext,\
bcmath,\
json,\
xml,\
fpm,\
intl,\
zip,\
apcu}

dnf -y module install mariadb
                          
dnf -y install nginx

dnf -y module reset php

dnf -y module install php:remi-7.4


systemctl start mariadb

systemctl enable --now mariadb

systemctl start nginx

systemctl enable --now nginx

systemctl start php-fpm

systemctl enable --now php-fpm


MYSQL_CONFIG=$(expect -c "

set timeout 3

spawn mysql_secure_installation

expect \"Enter current password for root (enter for none):\"
send \"$CURRENT_MYSQL_PASSWORD\r\"

expect \"root password?\"
send \"y\r\"

expect \"New password:\"
send \"$NEW_MYSQL_PASSWORD\r\"

expect \"Re-enter new password:\"
send \"$NEW_MYSQL_PASSWORD\r\"

expect \"Remove anonymous users?\"
send \"y\r\"

expect \"Disallow root login remotely?\"
send \"y\r\"

expect \"Remove test database and access to it?\"
send \"y\r\"

expect \"Reload privilege tables now?\"
send \"y\r\"

expect eof
")

echo "${MYSQL_CONFIG}"

mysql -u root -p$NEW_MYSQL_PASSWORD -e "CREATE DATABASE $NEW_DB character set utf8 collate utf8_bin;"

mysql -u root -p$NEW_MYSQL_PASSWORD -e "GRANT ALL PRIVILEGES ON $NEW_DB_USER.* TO $NEW_DB@'localhost' IDENTIFIED BY '$NEW_DB_PASSWORD';"

mysql -u root -p$NEW_MYSQL_PASSWORD -e "FLUSH PRIVILEGES;"


git clone $DOWNLOAD_LINK /usr/share/nginx/html
 
cp /usr/share/nginx/html/osTicket/include/ost-sampleconfig.php /usr/share/nginx/html/osTicket/include/ost-config.php 
  
chown -R nginx:nginx /usr/share/nginx/html/osTicket

chmod 0666 /usr/share/nginx/html/osTicket/include/ost-config.php


firewall-cmd --add-service={http,https} --permanent

firewall-cmd --reload


dnf -y remove expect

systemctl restart nginx php-fpm

reboot
