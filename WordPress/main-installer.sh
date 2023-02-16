#!/bin/bash
#
#INSTALLING WORDPRESS ON CENTOS 7
#Written by: Luis Fernández
#EMAIL: lfernandez2803 AT gmail dot com
#Last update: 15 of February of 2023
#
#
# -- THIS IMPORTANT -- PLEASE READ
#
# -- You must change the value of the variables according your configuration
#
# -- SELINUX MUST BE IN DISABLED MODE
#
# -- You must install previously
#	-- epel-release
#	-- fedoraproject repo
#	-- remi repo
#	-- mariadb repo
# 

PATH=$PATH:/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin

DOWNLOAD_LINK="http://wordpress.org/latest.tar.gz"
DOWNLOADED_FILE="latest.tar.gz"
AUTH_KEYS="https://api.wordpress.org/secret-key/1.1/salt/"
CURRENT_MYSQL_PASSWORD=' '
NEW_MYSQL_PASSWORD='r00t_p@ssw0rd'    #Must be change
NEW_DB_USER='w0rdpr3ss_us3r'          #Must be change
NEW_DB_PASSWORD='w0rdpr3ss_p@ssw0rd'  #Must be change
NEW_DB='w0rdpr3ss_db'                 #Must be change

#yum -y install \
#epel-release \
#https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm \
#https://rpms.remirepo.net/enterprise/remi-release-7.rpm

yum -y update

yum-config-manager --enable   remi-php81

yum -y install \
yum-utils \
vim \
expect \
wget \
MariaDB-server \
MariaDB-client \
httpd \
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

systemctl start mariadb
systemctl enable mariadb
systemctl start httpd
systemctl enable httpd

MYSQL_CONFIG=$(expect -c "
set timeout 3
spawn mariadb-secure-installation
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

mysql -u root -p$NEW_MYSQL_PASSWORD -e "CREATE DATABASE $NEW_DB character set utf8;" #collate utf8_bin

mysql -u root -p$NEW_MYSQL_PASSWORD -e "GRANT ALL PRIVILEGES ON $NEW_DB.* TO $NEW_DB_USER@'localhost' IDENTIFIED BY '$NEW_DB_PASSWORD';"

mysql -u root -p$NEW_MYSQL_PASSWORD -e "FLUSH PRIVILEGES;"

wget -P /usr/local/src/ $DOWNLOAD_LINK
wget -P /usr/local/src/ $AUTH_KEYS
tar -xzvf /usr/local/src/$DOWNLOADED_FILE -C /var/www/html/
mkdir /var/www/html/wordpress/wp-content/uploads
cp /var/www/html/wordpress/wp-config-sample.php /var/www/html/wordpress/wp-config.php
chown -R apache:apache /var/www/html/*
chmod -R 777 /var/www/html/wordpress

sed -i "s/database_name_here/$NEW_DB/g" /var/www/html/wordpress/wp-config.php
sed -i "s/username_here/$NEW_DB_USER/g" /var/www/html/wordpress/wp-config.php
sed -i "s/password_here/$NEW_DB_PASSWORD/g" /var/www/html/wordpress/wp-config.php

sed -i "/define( 'AUTH_KEY'/d" /var/www/html/wordpress/wp-config.php
sed -i "/define( 'SECURE_AUTH_KEY/d" /var/www/html/wordpress/wp-config.php
sed -i "/define( 'LOGGED_IN_KEY/d" /var/www/html/wordpress/wp-config.php
sed -i "/define( 'NONCE_KEY'/d" /var/www/html/wordpress/wp-config.php
sed -i "/define( 'AUTH_SALT'/d" /var/www/html/wordpress/wp-config.php
sed -i "/define( 'SECURE_AUTH_SALT'/d" /var/www/html/wordpress/wp-config.php
sed -i "/define( 'LOGGED_IN_SALT'/d" /var/www/html/wordpress/wp-config.php
sed -i "/define( 'NONCE_SALT'/d" /var/www/html/wordpress/wp-config.php

yum -y remove expect
systemctl restart httpd