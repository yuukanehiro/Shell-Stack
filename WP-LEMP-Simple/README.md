WP-LEMP-Simple
====

Overview

## Description

Simple Install WordPress, Nginx, PHP-FPM, PHP71, MySQL5.6


## Requirement

1. AWS EC2
2. AMI: CentOS Linux 7 x86_64 HVM EBS ENA 1901_01-b7ee8a69-ee97-4a49-9e68-afaee216db2e-ami-05713873c6794f575.4 (ami-045f38c93733dd48d)
3. ALB + ACM(HTTPS) configured


## Usage


<p>1. Download Shell-Stack</p>

```
$ sudo su -
$ yum -y install wget git unzip
$ wget https://github.com/yuukanehiro/Shell-Stack/archive/master.zip
$ unzip master.zip
$ cd $HOME/Shell-Stack-master/WP-LEMP-Simple
```


<p>2. Change Directory</p>

```
$ cd ./Shell-Stack/WP-LEMP-Simple-master/
```


<p>3. Setting Environment</p>

```
$ vi .env
```

<p>4. Execute!</p>

```
$ source .env
$ sh 1_init.sh
```


<p>5. hosts or DNS</p>

```
●hosts

192.168.11.101 example.net www.example.net
```

<p>6. Access!</p>

http://www.example.net/





## Author

[yuu kanehiro](https://github.com/yuukanehiro)
