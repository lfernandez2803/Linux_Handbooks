# What is Zabbix?

<img src="https://assets.zabbix.com/dist/images/logo.fd87efa6da9bed3fd8c9.svg" alt="zabbix" style="width:200px;"/>

Zabbix is an open source monitoring software tool for diverse IT components, including networks, servers, virtual machines (VMs) and cloud services. Zabbix provides monitoring metrics, such as network utilization, CPU load and disk space consumption. The software monitors operations on Linux, Hewlett Packard Unix (HP-UX), Mac OS X, Solaris and other operating systems (OSes); however, Windows monitoring is only possible through agents.

---
## Requirements
* An instance with centos stream 9 installed
* LAMP environment (web server, database server and PHP)
* A user with sudo permissions
* Internet
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

Enable SELinux  boolean “httpd_can_connect_zabbix” that will allow http daemon to connect to Zabbix:

```sh
setsebool -P httpd_can_connect_zabbix 1
```

To allow http daemon to connect to remote database through SELinux

```sh
setsebool -P httpd_can_network_connect_db 1
```

Enable SELinux  boolean “zabbix_can_network” that will allow Zabbix to connect to all TCP ports :

```sh
setsebool -P zabbix_can_network on
```

And to avoid error “cannot start HA manager: timeout while waiting for HA manager registration” enable daemons_enable_cluster_mode with this command:

```sh
setsebool -P daemons_enable_cluster_mode on
```

### SELinux in disabled mode

Open the /etc/selinux/config file and change the SELINUX value to disabled:

```sh
vim /etc/selinux/config
```

```vim
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
```

---

## Pre-installation

Before installing any new software, updating the system is always a good idea. To do this, open a terminal and run the following commands:

```sh
dnf -y upgrade --refresh
```

To access the Remi PHP repository, it is necessary first to install the EPEL (Extra Packages for Enterprise Linux) repository. EPEL is a valuable resource, particularly for new users of distributions like CentOS Stream, which is built on RHEL and provides a vast array of commonly used software packages for Enterprise Linux.

While this is optional for EL9, it is recommended to enable the CRB.

```sh
dnf config-manager --set-enabled crb
```

With the CRB enabled, execute the following command to install both versions of EPEL for EL9.

```sh
dnf -y install \
    https://dl.fedoraproject.org/pub/epel/epel-release-latest-9.noarch.rpm \
    https://dl.fedoraproject.org/pub/epel/epel-next-release-latest-9.noarch.rpm
```

Use the command below to import the EL 9 Remi repository.

```sh
dnf -y install dnf-utils http://rpms.remirepo.net/enterprise/remi-release-9.rpm
```

## Installation

1. ### Installation of repositories and utilities

Install utilities:

```sh
dnf -y upgrade
dnf -y install wget vim policycoreutils-python-utils dnf-utils firewalld
```

Disable Zabbix packages provided by EPEL, if you have it installed. Edit file /etc/yum.repos.d/epel.repo and add the following statement.

```vim
[epel]
...
excludepkgs=zabbix*
```

Proceed with installing zabbix repository.

```sh
rpm -Uvh https://repo.zabbix.com/zabbix/6.2/rhel/9/x86_64/zabbix-release-6.2-3.el9.noarch.rpm
dnf clean all
```

2. ### MariaDB installation

Here is your custom MariaDB DNF/YUM repository entry for CentOS. Copy and paste it into a file under /etc/yum.repos.d (we suggest naming the file MariaDB.repo or something similar).

```sh
vim /etc/yum.repos.d/MariaDB.repo
```

```vim
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
```

After the file is in place, install MariaDB with:

```sh
dnf -y install MariaDB-server MariaDB-client
```

Once the installation is complete, enable MariaDB using the commands below:

```sh
systemctl start mariadb
systemctl enable mariadb
```

Secure your Database server after installation:

```sh
mariadb-secure-installation
```

```vim
NOTE: RUNNING ALL PARTS OF THIS SCRIPT IS RECOMMENDED FOR ALL MariaDB
      SERVERS IN PRODUCTION USE!  PLEASE READ EACH STEP CAREFULLY!

In order to log into MariaDB to secure it, we'll need the current
password for the root user. If you've just installed MariaDB, and
haven't set the root password yet, you should just press enter here.

Enter current password for root (enter for none):
OK, successfully used password, moving on...

Setting the root password or using the unix_socket ensures that nobody
can log into the MariaDB root user without the proper authorisation.

You already have your root account protected, so you can safely answer 'n'.

Switch to unix_socket authentication [Y/n] Y
Enabled successfully!
Reloading privilege tables..
 ... Success!


You already have your root account protected, so you can safely answer 'n'.

Change the root password? [Y/n] Y
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

Remove anonymous users? [Y/n] Y
 ... Success!

Normally, root should only be allowed to connect from 'localhost'.  This
ensures that someone cannot guess at the root password from the network.

Disallow root login remotely? [Y/n] Y
 ... Success!

By default, MariaDB comes with a database named 'test' that anyone can
access.  This is also intended only for testing, and should be removed
before moving into a production environment.

Remove test database and access to it? [Y/n] Y
 - Dropping test database...
 ... Success!
 - Removing privileges on test database...
 ... Success!

Reloading the privilege tables will ensure that all changes made so far
will take effect immediately.

Reload privilege tables now? [Y/n] Y
 ... Success!

Cleaning up...

All done!  If you've completed all of the above steps, your MariaDB
installation should now be secure.

Thanks for using MariaDB!
```

Create initial database
Run the following on your database host:

```sql
mysql -uroot -p
password

mysql> create database zabbix character set utf8mb4 collate utf8mb4_bin;
mysql> create user zabbix@localhost identified by 'password';
mysql> grant all privileges on zabbix.* to zabbix@localhost;
mysql> set global log_bin_trust_function_creators = 1;
mysql> flush privileges;
mysql> quit;
```

3. ### Apache installation

Install the httpd package with:

```sh                       
dnf -y install httpd
```

After the installation is finished, run the following commands to enable and start the server:

```sh
systemctl start httpd
systemctl enable --now httpd
```

4. ### PHP installation

Activate the version of PHP you want to install

```sh
dnf module enable php:remi-8.2 -y
```

Install the php package with:

```sh
dnf -y install \
php \
php-{cli,\
pear,\
cgi,\
imap,\
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
```
 
After the installation is finished, run the following commands to enable and start the server:

```sh
systemctl start php-fpm
systemctl enable --now php-fpm
```

5. ### Zabbix installation

Install Zabbix server, frontend, agent

```sh
dnf -y install \
zabbix-server-mysql \
zabbix-web-mysql \
zabbix-apache-conf \
zabbix-sql-scripts \
zabbix-selinux-policy \
zabbix-agent
```

Configure the database for Zabbix server. Edit file /etc/zabbix/zabbix_server.conf

```sh
DBName=zabbix
DBUser=zabbix
vim /etc/zabbix/zabbix_server.conf
```

```vim
DBPassword=password
```

6. ### Firewall configuration

Open http and https ports in the firwalld:

```sh
firewall-cmd --add-service={http,https} --permanent
firewall-cmd --add-port={10051/tcp,10050/tcp} --permanent
firewall-cmd --reload
```

7. ### Last steps

On Zabbix server host import initial schema and data. You will be prompted to enter your newly created password.

```sh
zcat /usr/share/zabbix-sql-scripts/mysql/server.sql.gz | mysql --default-character-set=utf8mb4 -uzabbix -p zabbix
```

Disable log_bin_trust_function_creators option after importing database schema.

```sql
mysql -uroot -p
password

mysql> set global log_bin_trust_function_creators = 0;
mysql> quit;
```

Start Zabbix server and agent processes and make it start at system boot.

```
systemctl restart zabbix-server zabbix-agent httpd php-fpm
```

```
systemctl enable zabbix-server zabbix-agent httpd php-fpm
```

Open Zabbix UI web page

The default URL for Zabbix UI when using Apache web server is http://host/zabbix