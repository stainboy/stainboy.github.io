---

title:  "MariaDB Galera Cluster and HAProxy Setup with Docker"
date:   2015-09-20
categories: docker
description: "This article shows how to setup mariadb galera cluster and haproxy with docker"
summary: "This article shows how to setup mariadb galera cluster and haproxy with docker"
---


# MariaDB Galera Cluster Setup #

### 1. Prerequisites ###
3 ubuntu 14.04 nodes with docker installed.

- node1 (e.g. 10.58.9.243)
- node2 (e.g. 10.58.9.244)
- node3 (e.g. 10.58.9.245) 

Make sure `hostname -i` shows the correct IP address of the node

### 2. Build the solution ###
    git clone https://github.com/stainboy/lean.git
    cd lean/mariadb-galera
    docker build --no-cache=true -t mariadb-galera:10.0.21

### 3. Start node1 (aka master) ###
Logon node1, then type the command to start the first node. (Replace the IP address with your own)

    docker run -d --name mariadb \
     -p 3306:3306 -p 4567:4567 -p 4568:4568 -p 4444:4444 \
     -v /path/to/data:/var/lib/mysql \
     -e MYSQL_ROOT_PASSWORD=12345 \
     -e MYSQL_CLUSTER_PEER=10.58.9.243,10.58.9.244,10.58.9.245 \
     -e MYSQL_CLUSTER_IP=`hostname -i` \
     -e MYSQL_CLUSTER_NAME=`hostname` \
     -e MYSQL_CLUSTER=new \
     mariadb-galera:10.0.21

Wait couple seconds until the server is up. Type the command to check the server startup status

    docker run --rm --name mariadb-client \
     --entrypoint /bin/bash \
     mariadb-galera:10.0.21 \
     -c "mysql -h `hostname -i` --protocol=TCP -u root -P 3306 -p'12345' -e \"show status like 'wsrep_%'\""

A successful result could contains the following entries. (Only part of the entries are listed here) 

    wsrep_local_state_comment       Synced
    wsrep_incoming_addresses        10.58.9.243:3306
    wsrep_cluster_size              1
    wsrep_ready                     ON


### 4. Start node2 ###
**Do not start node2 until you see a successful result from node1.**

Logon node2, then type the command to start the second node. (Again, replace the IP address with your own)

    docker run -d --name mariadb \
     -p 3306:3306 -p 4567:4567 -p 4568:4568 -p 4444:4444 \
     -v /path/to/data:/var/lib/mysql \
     -e MYSQL_ROOT_PASSWORD=12345 \
     -e MYSQL_CLUSTER_PEER=10.58.9.243,10.58.9.244,10.58.9.245 \
     -e MYSQL_CLUSTER_IP=`hostname -i` \
     -e MYSQL_CLUSTER_NAME=`hostname` \
     -e MYSQL_CLUSTER=join \
     mariadb-galera:10.0.21

Again, wait couple seconds until the server is up. Type the command to check the server startup status

    docker run --rm --name mariadb-client \
     --entrypoint /bin/bash \
     mariadb-galera:10.0.21 \
     -c "mysql -h `hostname -i` --protocol=TCP -u root -P 3306 -p'12345' -e \"show status like 'wsrep_%'\""

A successful result could contains the following entries. (Only part of the entries are listed here) 

    wsrep_local_state_comment       Synced
    wsrep_incoming_addresses        10.58.9.243:3306,10.58.9.244:3306
    wsrep_cluster_size              2
    wsrep_ready                     ON

### 5. Start node3 ###
**Do not start node3 until you see a successful result from node2.**

Logon node3, then type the command to start the third node

    docker run -d --name mariadb \
     -p 3306:3306 -p 4567:4567 -p 4568:4568 -p 4444:4444 \
     -v /path/to/data:/var/lib/mysql \
     -e MYSQL_ROOT_PASSWORD=12345 \
     -e MYSQL_CLUSTER_PEER=10.58.9.243,10.58.9.244,10.58.9.245 \
     -e MYSQL_CLUSTER_IP=`hostname -i` \
     -e MYSQL_CLUSTER_NAME=`hostname` \
     -e MYSQL_CLUSTER=join \
     mariadb-galera:10.0.21

Once more, wait couple seconds until the server is up. Type the command to check the server startup status

    docker run --rm --name mariadb-client \
     --entrypoint /bin/bash \
     mariadb-galera:10.0.21 \
     -c "mysql -h `hostname -i` --protocol=TCP -u root -P 3306 -p'12345' -e \"show status like 'wsrep_%'\""

A successful result could contains the following entries. (Only part of the entries are listed here) 

    wsrep_local_state_comment       Synced
    wsrep_incoming_addresses        10.58.9.243:3306,10.58.9.244:3306,10.58.9.245:3306
    wsrep_cluster_size              3
    wsrep_ready                     ON

### 6. Test cluster ###
Start mysql client, input password 12345

    docker run -it --rm --name mariadb-client \
     --entrypoint /bin/bash \
     mariadb-galera:10.0.21

    mysql -h 10.58.9.243 --protocol=TCP -u root -P 3306 -p'12345'

Show cluster status

    mysql> show status like 'wsrep%';

Show schemas

    mysql> show databases;

Show users

    mysql> select user from mysql.user;

Test database/table replication

    mysql> CREATE DATABASE clustertest;
    mysql> CREATE TABLE clustertest.mycluster ( id INT NOT NULL AUTO_INCREMENT, name VARCHAR(50), ipaddress VARCHAR(20), PRIMARY KEY(id));
    mysql> INSERT INTO clustertest.mycluster (name, ipaddress) VALUES ("db1", "10.0.2.5");
    mysql> INSERT INTO clustertest.mycluster (name, ipaddress) VALUES ("db1", "10.0.2.6");

Go to another node and check the result

    mysql -h 10.58.9.244 --protocol=TCP -u root -P 3306 -p -e "select * from clustertest.mycluster"

Test grant permission

    mysql> create user miles;
    mysql> create schema milescc;
    mysql> grant all on milescc.* to 'miles'@'%';

### 7. When a node dead ###
Go to the dead node (**e.g. node1 - 10.58.9.243**), type the command to rejoin cluster

    docker run -d --name mariadb \
     -p 3306:3306 -p 4567:4567 -p 4568:4568 -p 4444:4444 \
     -v /path/to/data:/var/lib/mysql \
     -e MYSQL_ROOT_PASSWORD=12345 \
     -e MYSQL_CLUSTER_PEER=10.58.9.243,10.58.9.244,10.58.9.245 \
     -e MYSQL_CLUSTER_IP=`hostname -i` \
     -e MYSQL_CLUSTER_NAME=`hostname` \
     -e MYSQL_CLUSTER=join \
     mariadb-galera:10.0.21

### 8. When the entire cluster dead ###
You will have to decide which node might have the latest data that you want. Then go to that node (**e.g. node2 - 10.58.9.244**), type the command to initiate the cluster

    docker run -d --name mariadb \
     -p 3306:3306 -p 4567:4567 -p 4568:4568 -p 4444:4444 \
     -v /path/to/data:/var/lib/mysql \
     -e MYSQL_ROOT_PASSWORD=12345 \
     -e MYSQL_CLUSTER_PEER=10.58.9.243,10.58.9.244,10.58.9.245 \
     -e MYSQL_CLUSTER_IP=`hostname -i` \
     -e MYSQL_CLUSTER_NAME=`hostname` \
     -e MYSQL_CLUSTER=new \
     mariadb-galera:10.0.21

After which, go to the rest of the nodes, type the command to join the cluster. **Make sure you start the slave node one by one after each node is fully up.**

    docker run -d --name mariadb \
     -p 3306:3306 -p 4567:4567 -p 4568:4568 -p 4444:4444 \
     -v /path/to/data:/var/lib/mysql \
     -e MYSQL_ROOT_PASSWORD=12345 \
     -e MYSQL_CLUSTER_PEER=10.58.9.243,10.58.9.244,10.58.9.245 \
     -e MYSQL_CLUSTER_IP=`hostname -i` \
     -e MYSQL_CLUSTER_NAME=`hostname` \
     -e MYSQL_CLUSTER=join \
     mariadb-galera:10.0.21


# HAProxy Setup #


### 1. Prerequisites ###
4 ubuntu 14.04 nodes with docker installed.

- node1 (e.g. 10.58.9.243) for db1
- node2 (e.g. 10.58.9.244) for db2
- node3 (e.g. 10.58.9.245) for db3
- node4 (e.g. 10.58.9.246) for haproxy


### 2. Build the solution ###
    git clone https://github.com/stainboy/lean.git
    cd lean/haproxy
    docker build --no-cache=true -t haproxy:1.5.14

### 3. Prepare haproxy.cfg ###
Go to node4, prepare haproxy.cfg manually. (Replace the IP address with your own)

    cat > ~/.haproxy.cfg << EOF
    global
        log         127.0.0.1   local0
        log         127.0.0.1   local1 notice
        maxconn     4096
        user        haproxy
        group       haproxy
        nbproc      1
        pidfile     /var/run/haproxy.pid

    defaults
        log         global
        option      tcplog
        option      dontlognull
        retries     3
        maxconn     4096
        option      redispatch
        timeout     connect 50000ms
        timeout     client  50000ms
        timeout     server  50000ms

    listen mariadb-galera-writes
        bind 0.0.0.0:3307
        mode tcp
        option mysql-check user haproxy
        server db1 10.58.9.243:3306 check
        server db2 10.58.9.244:3306 check backup
        server db3 10.58.9.245:3306 check backup

    listen mariadb-galera-reads
        bind 0.0.0.0:3306
        mode tcp
        balance leastconn
        option mysql-check user haproxy
        server db1 10.58.9.243:3306 check
        server db2 10.58.9.244:3306 check
        server db3 10.58.9.245:3306 check

    # HAProxy web ui
    listen stats 0.0.0.0:9000
        mode http
        stats enable
        stats uri /
        stats realm HAProxy\ Statistics
        stats auth haproxy:12345
        stats admin if TRUE
    EOF

### 4. Start haproxy ###
Type the command to start haproxy.

    docker run -d --name haproxy \
     -p 3306:3306 -p 3307:3307 -p 5672:5672 -p 15672:15672 -p 9000:9000 \
     -v ~/.haproxy.cfg:/etc/haproxy/haproxy.cfg:ro \
     haproxy:1.5.14

### 5. Test cluster ###
Open browser and goto http://10.58.9.246:9000, login as haproxy/12345. Check the haproxy status.

Start mysql client, input password 12345

    docker run -it --rm --name mariadb-client \
     --entrypoint /bin/bash \
     mariadb-galera:10.0.21

    mysql -h 10.58.9.246 --protocol=TCP -u root -P 3306 -p

Show cluster status

    mysql> show status like 'wsrep%';

Show schemas

    mysql> show databases;

Show users

    mysql> select user from mysql.user;

### 6. When cluster nodes changed ###
Edit ~/.haproxy.cfg and type command

    docker restart -t 0 haproxy

### 7. When haproxy is dead ###
Make sure ~/.haproxy.cfg is correct and redo step #4.


##References##

- [http://blog.laimbock.com/2014/07/08/howto-setup-mariadb-galera-cluster-10-on-centos/](http://blog.laimbock.com/2014/07/08/howto-setup-mariadb-galera-cluster-10-on-centos/)
- [http://blog.laimbock.com/2014/10/01/howto-setup-high-available-haproxy-with-keepalived/](http://blog.laimbock.com/2014/10/01/howto-setup-high-available-haproxy-with-keepalived/)