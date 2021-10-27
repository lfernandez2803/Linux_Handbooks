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

~~~
setsebool -P httpd_can_network_connect 1
~~~

~~~
semanage fcontext -a -t httpd_sys_rw_content_t "/usr/share/nginx/html/osTicket(/.*)?"
~~~

~~~
restorecon -Rv /usr/share/nginx/html/osTicket/
~~~

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

~~~
shutdown -r now
~~~

---
## Installation

1. ### Installation of repositories and utilities

Install repositories:

~~~
dnf -y install https://dl.fedoraproject.org/pub/epel/epel-release-latest-8.noarch.rpm
~~~

~~~
dnf -y install https://rpms.remirepo.net/enterprise/remi-release-8.rpm
~~~

Update the system:

~~~
dnf -y update
~~~

Install utilities:

~~~
dnf -y install yum-utils unzip vim git
~~~

2. ### MariaDB installation

Install the MariaDB package with:

~~~
dnf -y module install @mariadb
~~~

After the installation is finished, run the following commands to enable and start the server:

~~~
systemctl start mariadb
~~~

~~~
systemctl enable --now mariadb
~~~

Secure your Database server after installation:

```mysql_secure_installation```

~~~
NOTE: RUNNING ALL PARTS OF THIS SCRIPT IS RECOMMENDED FOR ALL MariaDB
      SERVERS IN PRODUCTION USE!  PLEASE READ EACH STEP CAREFULLY!


In order to log into MariaDB to secure it, we'll need the current
password for the root user.  If you've just installed MariaDB, and
you haven't set the root password yet, the password will be blank,
so you should just press enter here.


Enter current password for root (enter for none): 
OK, successfully used password, moving on...


Setting the root password ensures that nobody can log into the MySQL
root user without the proper authorisation.


Set root password? [Y/n] Y
New password: 
Re-enter new password: 
Password updated successfully!
Reloading privilege tables..
 ... Success!


By default, a MariaDB installation has an anonymous user, allowing anyone
to log into MariaDB without having to have a user account created for
them.  This is intended only for testing, and to make the installation
go a bit smoother.  You should remove them before moving into a
production environment.


Remove anonymous users? [Y/n] y
 ... Success!


Normally, root should only be allowed to connect from 'localhost'.  This
ensures that someone cannot guess at the root password from the network.


Disallow root login remotely? [Y/n] y
 ... Success!


By default, MariaDB comes with a database named 'test' that anyone can
access.  This is also intended only for testing, and should be removed
before moving into a production environment.


Remove test database and access to it? [Y/n] y
 - Dropping test database...
 ... Success!
 - Removing privileges on test database...
 ... Success!


Reloading the privilege tables will ensure that all changes made so far
will take effect immediately.


Reload privilege tables now? [Y/n] y
 ... Success!


Cleaning up...


All done!  If you've completed all of the above steps, your MariaDB
installation should now be secure.


Thanks for using MariaDB!
~~~

Login to your database server as root user and create a database for osTicket:

~~~
mysql -u root -p
~~~

~~~
CREATE DATABASE osticket_db;
GRANT ALL PRIVILEGES ON osticket_db.* TO osticket_user@localhost IDENTIFIED BY "Str0ngDBP@ssw0rd";
FLUSH PRIVILEGES;
QUIT;
~~~

3. ### Nginx installation

Install the nginx package with:

~~~                         
dnf -y install nginx
~~~

After the installation is finished, run the following commands to enable and start the server:

~~~
systemctl start nginx
~~~

~~~
systemctl enable --now nginx
~~~

4. ### PHP installation

Install the php package with:

~~~
dnf -y install php php-{pear,cgi,common,curl,mbstring,gd,mysqlnd,gettext,bcmath,json,xml,fpm,intl,zip,apcu}
~~~

~~~
dnf -y module reset php
~~~

~~~
dnf -y module install php:remi-7.4
~~~

After the installation is finished, run the following commands to enable and start the server:

~~~
systemctl start php-fpm
~~~

~~~
systemctl enable --now php-fpm
~~~

5. ### OsTicket installation

Download latest release of osTicket:

~~~
git clone $DOWNLOAD_LINK /usr/share/nginx/html
~~~

Next create an osTicket configuration file:

~~~
cp /usr/share/nginx/html/osTicket/include/ost-sampleconfig.php /usr/share/nginx/html/osTicket/include/ost-config.php 
~~~

Change ownership of osTicket web directory to nginx user and group:

~~~
chown -R nginx:nginx /usr/share/nginx/html/osTicket
~~~

~~~
chmod 0666 /usr/share/nginx/html/osTicket/include/ost-config.php
~~~

6. ### Firewall configuration

Open http and https ports in the firwalld:

~~~
firewall-cmd --add-service={http,https} --permanent
~~~

~~~
firewall-cmd --reload
~~~

7. ### Last steps

Restart the nginx and php-fpm services:

~~~
systemctl restart nginx php-fpm
~~~

Reboot the server:

~~~
reboot
~~~
