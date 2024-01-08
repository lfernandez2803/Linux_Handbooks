#!/bin/bash
#
#INSTALLING OSTICKET V1.18.x ON CENTOS STREAM 9
#Written by: Luis Fernández
#EMAIL: l.ed.fernandez.a AT gmail dot com
#Last update: 08 of January of 2024
#
#
# -- THIS IMPORTANT -- PLEASE READ
#
# -- You must change the value of the variables according your configuration
#
# 

PATH=$PATH:/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin

DOWNLOAD_LINK="https://github.com/osTicket/osTicket.git"
CURRENT_MYSQL_PASSWORD=' '
NEW_MYSQL_PASSWORD='r00t_p@ssw0rd'   #Change it if you want to
NEW_DB_USER='0st1ck3t_us3r'          #Change it if you want to
NEW_DB_PASSWORD='0st1ck3t_p@ssw0rd'  #Change it if you want to
NEW_DB='0st1ck3t_db'                 #Change it if you want to

cat <<\EOF >> /etc/yum.repos.d/MariaDB.repo
# MariaDB 10.11 CentOS repository list - created 2023-02-27 14:42 UTC
# https://mariadb.org/download/
[mariadb]
name = MariaDB
# rpm.mariadb.org is a dynamic mirror if your preferred mirror goes offline. See https://mariadb.org/mirrorbits/ for details.
# baseurl = https://rpm.mariadb.org/10.11/centos/$releasever/$basearch
baseurl = https://mirrors.gigenet.com/mariadb/yum/10.11/centos/$releasever/$basearch
# gpgkey = https://rpm.mariadb.org/RPM-GPG-KEY-MariaDB
gpgkey = https://mirrors.gigenet.com/mariadb/yum/RPM-GPG-KEY-MariaDB
gpgcheck = 1
EOF

dnf -y upgrade --refresh
dnf config-manager --set-enabled crb

dnf -y install \
    https://dl.fedoraproject.org/pub/epel/epel-release-latest-9.noarch.rpm \
    https://dl.fedoraproject.org/pub/epel/epel-next-release-latest-9.noarch.rpm \
    https://rpms.remirepo.net/enterprise/remi-release-9.rpm 

dnf -y upgrade

dnf -y install \
wget \
vim \
policycoreutils-python-utils \
dnf-utils \
firewalld \
git \
expect

dnf -y install \
nginx \
MariaDB-server \
MariaDB-client

dnf -y module reset php
dnf module -y enable php:remi-8.2

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

systemctl start firewalld
systemctl enable --now firewalld
systemctl start nginx
systemctl enable --now nginx
systemctl start mariadb
systemctl enable --now mariadb
systemctl start php-fpm
systemctl enable --now php-fpm

firewall-cmd --permanent --zone=public --add-service=http 
firewall-cmd --permanent --zone=public --add-service=https
firewall-cmd --reload

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

git clone $DOWNLOAD_LINK /usr/local/src
cp -r /usr/local/src/osTicket /usr/share/nginx/html/
cp /usr/share/nginx/html/osTicket/include/ost-sampleconfig.php /usr/share/nginx/html/osTicket/include/ost-config.php  
chown -R nginx:nginx /usr/share/nginx/html/osTicket
chmod 0666 /usr/share/nginx/html/osTicket/include/ost-config.php

mysql -u root -p$NEW_MYSQL_PASSWORD -e "CREATE DATABASE $NEW_DB character set utf8 collate utf8_bin;"
mysql -u root -p$NEW_MYSQL_PASSWORD -e "GRANT ALL PRIVILEGES ON $NEW_DB.* TO $NEW_DB_USER@'localhost' IDENTIFIED BY '$NEW_DB_PASSWORD';"
mysql -u root -p$NEW_MYSQL_PASSWORD -e "FLUSH PRIVILEGES;"

dnf -y remove expect
systemctl restart nginx php-fpm
reboot
