# What is Graylog?

<img src="https://assets.stickpng.com/images/62dea679ff3c6e4b8b5de8b9.png" alt="graylog" style="width:200px;"/>

Graylog is defined in terms of log management platform for collecting, indexing, and analyzing both structured and unstructured data from almost any source.

---

## Requirements

- An instance with centos stream 9 installed
- LAMP environment (web server, database server and PHP)
- A user with sudo permissions
- Internet

---

## Steps before installation

### What is SELinux?

Security Enhanced Linux or SELinux is a security mechanism built into the Linux kernel used by RHEL-based distributions.

SELinux adds an additional layer of security to the system by allowing administrators and users to control access to objects based on policy rules.

SELinux policy rules specify how processes and users interact with each other as well as how processes and users interact with files. When there is no rule explicitly allowing access to an object, such as for a process opening a file, access is denied.

SELinux has three modes of operation:

- Enforcing: SELinux allows access based on SELinux policy rules.
- Permissive: SELinux only logs actions that would have been denied if running in enforcing mode. This mode is useful for debugging and creating new policy rules.
- Disabled: No SELinux policy is loaded, and no messages are logged.

By default, in CentOS 8, SELinux is enabled and in **enforcing mode.** It is highly recommended to keep SELinux in enforcing mode. However, sometimes it may interfere with the functioning of some application, and you need to set it to the permissive mode or disable it completely.

**Now you have to decide if you want work with SELinux in enforcing mode or SELinux in disabled mode:**

### SELinux in enforcing mode

You must run the following commands in your instance:

```sh
setsebool -P httpd_can_network_connect 1
semanage port -a -t http_port_t -p tcp 9000
semanage port -a -t http_port_t -p tcp 9200
semanage port -a -t mongod_port_t -p tcp 27017
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
dnf -y install wget vim policycoreutils-python-utils dnf-utils firewalld wpgen
```

2. ### MongoDB installation

First, add the repository file /etc/yum.repos.d/mongodb-org.repo with the following contents:

```sh
vim /etc/yum.repos.d/mongodb-org-6.0.repo
```

```vim
[mongodb-org-6.0]
name=MongoDB Repository
baseurl=https://repo.mongodb.org/yum/redhat/\$releasever/mongodb-org/6.0/x86_64/
gpgcheck=1
enabled=1
gpgkey=https://www.mongodb.org/static/pgp/server-6.0.asc
EOF
```

After that, install the latest release of MongoDB:

```sh
dnf -y install mongodb-org
```

Once the installation is complete, enable MongoDB using the commands below:

```sh
systemctl start mongod
systemctl enable mongod
```

3. ### OpenSearch installation

If you are using OpenSearch as your data node, then follow the steps below to install OpenSearch.

You may prefer to disable transparent hugepages to improve performance before installing:

```sh
echo "Description=Disable Transparent Huge Pages (THP)
DefaultDependencies=no
After=sysinit.target local-fs.target
[Service]
Type=oneshot
ExecStart=/bin/sh -c 'echo never | tee /sys/kernel/mm/transparent_hugepage/enabled > /dev/null'
[Install]
WantedBy=basic.target" | tee /etc/systemd/system/disable-transparent-huge-pages.service
```

Enable the service using the commands below:

```sh
systemctl daemon-reload
systemctl enable disable-transparent-huge-pages.service
systemctl start disable-transparent-huge-pages.service
```

Download and install the OpenSearch.*.rpm package:

```sh
wget -P /usr/local/src/ https://artifacts.opensearch.org/releases/bundle/opensearch/2.6.0/opensearch-2.6.0-linux-x64.rpm

rpm -ivh /usr/local/src/opensearch-2.6.0-linux-x64.rpm
```

Edit the opensearch.yml file:

```sh
vim /etc/opensearch/opensearch.yml
```

```vim
cluster.name: $clustername
action.auto_create_index: false
plugins.security.disabled: true
network.host: 0.0.0.0  
discovery.type: single-node
```

After the installation succeeds, enable the OpenSearch service:

```sh
systemctl start opensearch
systemctl enable opensearch
```

4. ### Graylog installation

Now install the Graylog repository configuration and Graylog Open itself with the following commands:

```sh
rpm -Uvh https://packages.graylog2.org/repo/packages/graylog-5.0-repository_latest.rpm
dnf -y install graylog-server
```

Edit the config file

Read the instructions within the configurations file and edit as needed, located at /etc/graylog/server/server.conf. Additionally add password_secret and root_password_sha2 as these are mandatory and Graylog will not start without them.

To create your root_password_sha2, run the following command:

```sh
echo -n "Enter Password: " && head -1 </dev/stdin | tr -d '\n' | sha256sum | cut -d" " -f1
```

To generate a password_secret:

```sh
pwgen -N 1 -s 96
```

To be able to connect to Graylog, set http_bind_address to the public host name or a public IP address of the machine with which you can connect.

The last step is to enable Graylog during the operating system’s start up:

```sh
systemctl daemon-reload
systemctl start graylog-server.service
systemctl enable graylog-server.service
```

5. ### Firewall configuration

Open http and https ports in the firwalld:

```sh
firewall-cmd --add-port=9000/tcp --permanent
firewall-cmd --reload
```

6. ### Last steps

The default URL for Graylog UI is http://host:9000