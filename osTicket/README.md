# What is osTicket?

<img src="https://docs.osticket.com/en/latest/_static/images/osticket-supsys-black-white.png" alt="osTicket" style="width:200px;"/>


osTicket is a widely-used open source support ticket system. It seamlessly integrates inquiries created via email, phone and web-based forms into a simple easy-to-use multi-user web interface. Manage, organize and archive all your support requests and responses in one place while providing your customers with accountability and responsiveness they deserve.

---
## Requirements
* An instance with centos 8 installed -- **I'll assume you already have it**
* nginx installation and configuration
* mariadb installation and configuration
---
## Steps before installation

### What is SELinux?

Security Enhanced Linux or SELinux is a security mechanism built into the Linux kernel used by RHEL-based distributions.

SELinux adds an additional layer of security to the system by allowing administrators and users to control access to objects based on policy rules.

SELinux policy rules specify how processes and users interact with each other as well as how processes and users interact with files. When there is no rule explicitly allowing access to an object, such as for a process opening a file, access is denied.

SELinux has three modes of operation:

* Enforcing: SELinux allows access based on SELinux policy rules.
* Permissive: SELinux only logs actions that would have been denied if running in enforcing mode. This mode is useful for debugging and creating new policy rules.
* Disabled: No SELinux policy is loaded, and no messages are logged.

By default, in CentOS 8, SELinux is enabled and in **enforcing mode.** It is highly recommended to keep SELinux in enforcing mode. However, sometimes it may interfere with the functioning of some application, and you need to set it to the permissive mode or disable it completely.

**Now you have to decide if you want work with SELinux in enforcing mode or SELinux in disabled mode:**

### SELinux in enforcing mode

You must run the following commands in your instance:

```bash
setsebool -P httpd_can_network_connect 1
```

```bash
semanage fcontext -a -t httpd_sys_rw_content_t "/usr/share/nginx/html/osTicket(/.*)?"
```

```bash
restorecon -Rv /usr/share/nginx/html/osTicket/
```

### SELinux in disabled mode

Open the /etc/selinux/config file and change the SELINUX value to disabled:

```vi /etc/selinux/config```
~~~
# This file controls the state of SELinux on the system.
# SELINUX= can take one of these three values:
#       enforcing - SELinux security policy is enforced.
#       permissive - SELinux prints warnings instead of enforcing.
#       disabled - No SELinux policy is loaded.
SELINUX=disabled
# SELINUXTYPE= can take one of these three values:
#     targeted - Targeted processes are protected,
#     minimum - Modification of targeted policy. Only selected processes are protected. 
#     mls - Multi Level Security protection.
SELINUXTYPE=targeted
~~~

Save the file and reboot the system:

```bash
shutdown -r now
```

---
## Installation

dnf -y install https://dl.fedoraproject.org/pub/epel/epel-release-latest-8.noarch.rpm \
https://rpms.remirepo.net/enterprise/remi-release-8.rpm

dnf -y update

dnf -y install yum-utils unzip vim git




dnf -y install php php-{pear,cgi,common,curl,mbstring,gd,mysqlnd,gettext,bcmath,json,xml,fpm,intl,zip,apcu}

dnf -y module reset php

dnf -y module install php:remi-7.4

systemctl start php-fpm

systemctl enable --now php-fpm





dnf -y module install mariadb

systemctl start mariadb

systemctl enable --now mariadb



                          
dnf -y install nginx

systemctl start nginx

systemctl enable --now nginx




mysql_secure_installation
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




systemctl restart nginx php-fpm

reboot
