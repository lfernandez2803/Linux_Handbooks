#!/bin/bash
#
#INSTALLING ZABBIX ON CENTOS STREAM 9
#Written by: Luis Fernández
#EMAIL: lfernandez2803 AT gmail dot com
#Last update: 27 of February of 2023
#
#
# -- THIS IMPORTANT -- PLEASE READ
#
# -- You must change the value of the variables according your configuration
#
# 

PATH=$PATH:/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin

DOWNLOAD_LINK="https://repo.zabbix.com/zabbix/6.2/rhel/9/x86_64/zabbix-release-6.2-3.el9.noarch.rpm"
CURRENT_MYSQL_PASSWORD=' '
NEW_MYSQL_PASSWORD='r00t_p@ssw0rd'   
NEW_DB_USER='z@bb1x_us3r'          
NEW_DB_PASSWORD='z@bb1x_p@ssw0rd'  
NEW_DB='z@bb1x_db'              

dnf -y upgrade

rpm -Uvh $DOWNLOAD_LINK

dnf clean all

dnf module enable php:remi-8.2 -y

dnf -y install \
policycoreutils-python-utils \
vim \
expect \
wget \
httpd \
MariaDB-server \
MariaDB-client \
php \
php-{cli,pear,\
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
apcu,\
opcache,\
imagick,\
xmlrpc,\
readline,\
memcached,\
redis,\
dom}

dnf -y install \
zabbix-server-mysql \
zabbix-web-mysql \
zabbix-apache-conf \
zabbix-sql-scripts \
zabbix-selinux-policy \
zabbix-agent

sed -i "s/DBName=zabbix/DBName=$NEW_DB/g" /etc/zabbix/zabbix_server.conf
sed -i "s/DBUser=zabbix/DBUser=$NEW_DB_USER/g" /etc/zabbix/zabbix_server.conf
sed -i "s/#DBPassword=/DBPassword=$NEW_DB_PASSWORD/g" /etc/zabbix/zabbix_server.conf

systemctl start mariadb
systemctl enable mariadb
systemctl start httpd
systemctl enable httpd
systemctl start php-fpm
systemctl enable --now php-fpm

MYSQL_CONFIG=$(expect -c "
set timeout 3
spawn mariadb-secure-installation
expect \"Enter current password for root (enter for none):\"
send \"$CURRENT_MYSQL_PASSWORD\r\"
expect \"Switch to unix_socket authentication\"
send \"y\r\"
expect \"Change the root password?\"
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

mysql -u root -p$NEW_MYSQL_PASSWORD -e "CREATE DATABASE $NEW_DB character set utf8mb4 collate utf8mb4_bin;"
mysql -u root -p$NEW_MYSQL_PASSWORD -e "CREATE USER $NEW_DB_USER@'localhost' IDENTIFIED BY '$NEW_DB_PASSWORD';"
mysql -u root -p$NEW_MYSQL_PASSWORD -e "GRANT ALL PRIVILEGES ON $NEW_DB.* TO $NEW_DB_USER@'localhost';"
mysql -u root -p$NEW_MYSQL_PASSWORD -e "SET GLOBAL log_bin_trust_function_creators = 1;"
mysql -u root -p$NEW_MYSQL_PASSWORD -e "FLUSH PRIVILEGES;"

systemctl start firewalld
systemctl enable firewalld
firewall-cmd --add-service={http,https} --permanent
firewall-cmd --add-port={10051/tcp,10050/tcp} --permanent
firewall-cmd --reload

zcat /usr/share/zabbix-sql-scripts/mysql/server.sql.gz | mysql --default-character-set=utf8mb4 -u$NEW_DB_USER -p$NEW_DB_PASSWORD $NEW_DB

mysql -u root -p$NEW_MYSQL_PASSWORD -e "set global log_bin_trust_function_creators = 0;"

systemctl restart zabbix-server zabbix-agent httpd php-fpm
systemctl enable zabbix-server zabbix-agent httpd php-fpm

setsebool -P httpd_can_connect_zabbix 1
setsebool -P zabbix_can_network on
setsebool -P daemons_enable_cluster_mode on

dnf -y remove expect
systemctl restart httpd