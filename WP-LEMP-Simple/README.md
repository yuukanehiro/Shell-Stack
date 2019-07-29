WP-LEMP-Simple
====

Overview

## Description

Simple Install WordPress, Nginx, PHP-FPM, PHP71, MySQL5.6


## Requirement

1. AWS EC2
2. AMI: CentOS Linux 7 x86_64 HVM EBS ENA 1901_01-b7ee8a69-ee97-4a49-9e68-afaee216db2e-ami-05713873c6794f575.4 (ami-045f38c93733dd48d)


## Usage

<p>1. Change root User</p>

```

$ sudo su

$ cd ./Shell-Stack/WP-LEMP-Simple/
```


<p>2. Setting Environment</p>

```
$ vi .env
```

<p>3. Execute!</p>

```
$ source .env

$ sh 1_init.sh
```


## Author

[yuu kanehiro](https://github.com/yuukanehiro)
