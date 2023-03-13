# What is Let's Encrypt?

<img src="https://upload.wikimedia.org/wikipedia/de/thumb/7/7c/Letsencrypt-logo-horizontal.svg/1200px-Letsencrypt-logo-horizontal.svg.png" alt="letsEncrypt" style="width:350px;"/>

Let’s Encrypt is a Certificate Authority (CA) that facilitates obtaining and installing free TLS/SSL certificates, thereby enabling encrypted HTTPS on web servers. It simplifies the process by working with clients, such as Certbot, to automate the necessary steps.

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
dnf install certbot python3-certbot-apache mod_ssl
```

To execute the interactive installation and obtain a certificate that is valid for multiple domains or subdomains, run the certbot command with:

```sh
certbot --apache -d example.com -d www.example.com
```

2. ### Setting Up Auto Renewal

The certbot Let’s Encrypt client has a renew command that automatically checks the currently installed certificates and tries to renew them if they are less than 30 days away from the expiration date. By using the --dry-run option, you can run a simulation of this task to test how renew works:

```sh
certbot renew --dry-run
```

A practical way to ensure your certificates will not get outdated is to create a [cron job](https://www.digitalocean.com/community/tutorials/how-to-use-cron-to-automate-tasks-on-a-vps) that will periodically execute the automatic renewal command for you.

The official Certbot documentation recommends running cron twice per day. This will ensure that, in case Let’s Encrypt initiates a certificate revocation, there will be no more than half a day before Certbot renews your certificate. The documentation suggests using the following command to add an appropriate cron job to the /etc/crontab crontab file:

```vim
echo "0 0,12 * * * root python3 -c 'import random; import time; time.sleep(random.random() * 3600)' && certbot renew -q" | sudo tee -a /etc/crontab > /dev/null
```