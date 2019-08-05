#!/bin/sh
set -e

# スクリプトディレクトリの取得
SCRIPT_DIR=`dirname $0`
cd $SCRIPT_DIR


## ===================================================================
#   構築シェル
## ===================================================================





## 時刻更新
sudo yum reinstall -y tzdata
sudo ln -sf /usr/share/zoneinfo/Japan /etc/localtime


sudo cat <<EOF > /etc/sysconfig/clock
ZONE="Japan"
UTC=true
EOF



# WEBユーザ追加
sudo useradd ${WEB_USER}






## リポジトリ設定 EPEL, Remi ===
sudo yum install -y yum-utils


sudo yum -y install epel-release && sudo yum -y upgrade epel-release
sudo rpm -Uvh --replacepkgs http://rpms.famillecollet.com/enterprise/remi-release-7.rpm
sudo yum-config-manager --enable remi-php71


# 置換 EPELを普段は利用しない
sed -i '6 s/enabled=1/enabled=0/g' /etc/yum.repos.d/epel.repo
##########################################################################################
#[epel]
#name=Extra Packages for Enterprise Linux 7 - $basearch
##baseurl=http://download.fedoraproject.org/pub/epel/7/$basearch
#metalink=https://mirrors.fedoraproject.org/metalink?repo=epel-7&arch=$basearch
#failovermethod=priority
#enabled=1 ←●これを変更する
#gpgcheck=1
#gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-EPEL-7

#[epel-debuginfo]
#name=Extra Packages for Enterprise Linux 7 - $basearch - Debug
##baseurl=http://download.fedoraproject.org/pub/epel/7/$basearch/debug
#metalink=https://mirrors.fedoraproject.org/metalink?repo=epel-debug-7&arch=$basearch
#failovermethod=priority
#enabled=0
#gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-EPEL-7
#gpgcheck=1

#[epel-source]
#name=Extra Packages for Enterprise Linux 7 - $basearch - Source
##baseurl=http://download.fedoraproject.org/pub/epel/7/SRPMS
#metalink=https://mirrors.fedoraproject.org/metalink?repo=epel-source-7&arch=$basearch
#failovermethod=priority
#enabled=0
#gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-EPEL-7
#gpgcheck=1
##########################################################################################






# Nginx リポジトリ設定
sudo cat << 'EOF' > /etc/yum.repos.d/nginx.repo
[nginx-stable]
name=nginx stable repo
baseurl=http://nginx.org/packages/centos/$releasever/$basearch/
gpgcheck=1
enabled=1
gpgkey=https://nginx.org/keys/nginx_signing.key

[nginx-mainline]
name=nginx mainline repo
baseurl=http://nginx.org/packages/mainline/centos/$releasever/$basearch/
gpgcheck=1
enabled=0
gpgkey=https://nginx.org/keys/nginx_signing.key
EOF




# 開発ツールインストール
sudo yum groupinstall -y "Development Tools"
sudo yum -y install git zip mailx unzip rsync
sudo yum -y install --enablerepo=epel htop



## Nginxインストール ===================================
sudo yum-config-manager --enable nginx-mainline
sudo yum info nginx
sudo yum install -y nginx


# WEBユーザをNginxグループに追加
sudo usermod -G nginx ${WEB_USER}


# Nginx設定ファイルバックアップ
sudo mv /etc/nginx/nginx.conf /etc/nginx/nginx.conf.org



sudo cat << EOF > /etc/nginx/nginx.conf
user  ${WEB_USER};
worker_processes      auto;
worker_cpu_affinity   auto;
worker_rlimit_nofile  4096;
error_log  /var/log/nginx/error.log warn;
pid        /var/run/nginx.pid;

events {
  worker_connections  1024;
}

http {
  include        /etc/nginx/mime.types;
  default_type   application/octet-stream;
  index          index.html index.php;
  server_tokens  off;
  access_log     off;
  charset        UTF-8;

  add_header  X-Content-Type-Options nosniff;
  add_header  X-XSS-Protection "1; mode=block";

  sendfile    on;
  tcp_nopush  on;
  keepalive_timeout  60;

  gzip  on;
  gzip_disable  "msie6";
  gzip_min_length  1024;
  gzip_types  text/css
              image/gif
              image/png
              image/jpeg
              application/javascript;

  server {
    listen  80 default_server;
    return  444;
    log_not_found  off;
  }

  include /etc/nginx/conf.d/*.conf;
}
EOF




# Nginxバーチャルホストファイル設定
sudo cat << 'EOF' > /etc/nginx/conf.d/${WP_SITENAME}.conf
server {
    listen       80;
    server_name  EXAMPLE.NET;
    return       301 https://www.EXAMPLE.NET$request_uri;
}

server {
    listen 80;
    server_name www.EXAMPLE.NET;

    root /var/www/vhosts/www.EXAMPLE.NET/httpdocs;
    index index.html index.php;


    # log files
    access_log /var/log/nginx/www.EXAMPLE.NET.access.log;
    error_log /var/log/nginx/www.EXAMPLE.NET.error.log;

    location = /favicon.ico {
        log_not_found off;
        access_log off;
    }

    location = /robots.txt {
        allow all;
        log_not_found off;
        access_log off;
    }

    location / {
        try_files $uri $uri/ /index.php?$args;

    }

    location ~ \.php$ {
        try_files $uri =404;
        fastcgi_pass unix:/var/run/php-fpm/php-fpm.sock;
        fastcgi_index   index.php;
        fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
        include fastcgi_params;
    }

    location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg)$ {
        expires max;
        log_not_found off;
    }

    # AWS ALBヘルスチェック設定 :削除するとALBから外れます。
    location /health {
        access_log off;
        return 204;
        break;
    }

}
EOF


# Nginxドメイン名置換
sudo sed -i "s/EXAMPLE.NET/${NAKED_DOMAIN}/g" /etc/nginx/conf.d/${WP_SITENAME}.conf





# WordPressダウンロード =================================
sudo yum install -y wget unzip rsync git
sudo wget https://ja.wordpress.org/latest-ja.tar.gz
sudo tar zxvf latest-*

sudo mkdir -p /var/www/vhosts/${WP_SITENAME}/httpdocs/
sudo rsync -arv ./wordpress/ /var/www/vhosts/${WP_SITENAME}/httpdocs/
sudo chown ${WEB_USER}:nginx -R /var/www/vhosts/
sudo rm -rf wordpress latest-ja.tar.gz





# PHPインストール =========================

sudo yum -y --enablerepo=remi-php71 install php php-mbstring php-fpm php-pdo php-mysqlnd php-gd

# php.ini 設定
sudo cp /etc/php.ini /etc/php.ini.org
sudo sed -i -e "s|expose_php = On|expose_php = Off|" /etc/php.ini
sudo sed -i -e "s|;date.timezone =|date.timezone = Asia/Tokyo|" /etc/php.ini
sudo sed -i -e "s|session.sid_length = 26|session.sid_length = 32|" /etc/php.ini
sudo sed -i -e "s|;mbstring.language = Japanese|mbstring.language = Japanese|" /etc/php.ini


# セッション権限設定
sudo chown ${WEB_USER}:nginx -R /var/lib/php/session


## PHP-FPM設定 ====================================================
sudo cp /etc/php-fpm.d/www.conf /etc/php-fpm.d/www.conf.org


sudo cat << EOF > /etc/php-fpm.d/www.conf
[global]
pid = /var/run/php-fpm/php-fpm.pid
error_log = /var/log/php-fpm/error.log
log_level = notice
emergency_restart_threshold = 0
emergency_restart_interval = 0
process_control_timeout = 0
daemonize = yes
events.mechanism = epoll
 
[www]
listen = /var/run/php-fpm/php-fpm.sock  
listen.backlog = -1
 
listen.owner = ${WEB_USER}
listen.group = nginx
listen.mode = 0666
 
user = ${WEB_USER}
group = nginx
 
pm = dynamic
pm.max_children =  30
pm.start_servers = 10
pm.min_spare_servers = 10
pm.max_spare_servers = 25
pm.max_requests = 30
pm.status_path = /phpfpm_status
 
request_slowlog_timeout = 300
request_terminate_timeout= 300
slowlog = /var/log/php-fpm/$pool-slow.log
EOF




## Nginx, PHP-FPM自動起動設定
sudo systemctl enable nginx
sudo systemctl start nginx
sudo systemctl status nginx

sudo systemctl enable php-fpm
sudo systemctl start php-fpm
sudo systemctl status php-fpm





## MySQL5.6インストール ===============
sudo yum remove -y mariadb-libs
sudo rm -rf /var/lib/mysql/


sudo yum localinstall -y http://dev.mysql.com/get/mysql57-community-release-el7-7.noarch.rpm
sudo yum-config-manager --disable mysql57-community
sudo yum-config-manager --enable mysql56-community
sudo yum -y install mysql-community-server


sudo systemctl enable mysqld
sudo systemctl start mysqld
sudo systemctl status mysqld






# WordPress用DBの作成
sudo mysql -u root  -e "create database $WP_DB"
sudo mysql -u root  -e "grant all privileges on $WP_DB.* to $WP_DBUSER@localhost identified by '$WP_DBPASS'"






## SELinux 無効化 ==============
sudo sed -i -e "s|SELINUX=enforcing|SELINUX=disabled|" /etc/sysconfig/selinux
sudo sed -i -e "s|SELINUX=enforcing|SELINUX=disabled|" /etc/selinux/config


## システム更新
sudo yum update -y


## 再起動 ===============
sudo reboot now






# 起動後は
# https://www.example.net
# にアクセスして下さい。
