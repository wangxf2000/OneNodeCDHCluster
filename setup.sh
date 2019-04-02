echo "------------------------------------------------------"
echo "-- Configure the OS"
echo never > /sys/kernel/mm/transparent_hugepage/defrag
echo never > /sys/kernel/mm/transparent_hugepage/enabled
# TODO make 2 above commands to be permanent
echo  "vm.swappiness = 1" >> /etc/sysctl.conf
sysctl vm.swappiness=1

echo "------------------------------------------------------"
echo "-- Install Java OpenJDK8 and other tools, and run 'os-generic-bootstrap.sh'"
yum install -y java-1.8.0-openjdk-devel vim wget curl git
curl -sSL https://raw.githubusercontent.com/cloudera/director-scripts/master/azure-bootstrap-scripts/os-generic-bootstrap.sh | sh

echo "------------------------------------------------------"
echo "-- Configure networking"
hostnamectl set-hostname `hostname -f`
echo "`hostname -I` `hostname`" >> /etc/hosts
sed -i "s/HOSTNAME=.*/HOSTNAME=`hostname`/" /etc/sysconfig/network
iptables-save > ~/firewall.rules
systemctl disable firewalld
systemctl stop firewalld
setenforce 0
sed -i 's/SELINUX=.*/SELINUX=permissive/' /etc/selinux/config

echo "------------------------------------------------------"
echo "-- Install CM and MariaDB"
wget https://archive.cloudera.com/cm6/6.2.0/redhat7/yum/cloudera-manager.repo -P /etc/yum.repos.d/
rpm --import https://archive.cloudera.com/cm6/6.2.0/redhat7/yum/RPM-GPG-KEY-cloudera
yum install -y cloudera-manager-daemons cloudera-manager-agent cloudera-manager-server mariadb-server
cat - >/etc/my.cnf <<EOF
[mysqld]
datadir=/var/lib/mysql
socket=/var/lib/mysql/mysql.sock
transaction-isolation = READ-COMMITTED
symbolic-links = 0

key_buffer = 16M
key_buffer_size = 32M
max_allowed_packet = 32M
thread_stack = 256K
thread_cache_size = 64
query_cache_limit = 8M
query_cache_size = 64M
query_cache_type = 1

max_connections = 550

log_bin=/var/lib/mysql/mysql_binary_log

server_id=1

binlog_format = mixed

read_buffer_size = 2M
read_rnd_buffer_size = 16M
sort_buffer_size = 8M
join_buffer_size = 8M

innodb_file_per_table = 1
innodb_flush_log_at_trx_commit  = 2
innodb_log_buffer_size = 64M
innodb_buffer_pool_size = 4G
innodb_thread_concurrency = 8
innodb_flush_method = O_DIRECT
innodb_log_file_size = 512M

[mysqld_safe]etc/my.cnf.d/mariadb.pidg
log-error=/var/log/mariadb/mariadb.log
pid-file=/var/run/mariadb/mariadb.pid

!includedir /etc/my.cnf.d
EOF

echo "------------------------------------------------------"
echo "--Enable and start MariaDB"
systemctl enable mariadb
systemctl start mariadb

echo "------------------------------------------------------"
echo "-- Install JDBC connector"
wget https://dev.mysql.com/get/Downloads/Connector-J/mysql-connector-java-5.1.46.tar.gz
tar zxvf mysql-connector-java-5.1.46.tar.gz
mkdir -p /usr/share/java/
cp mysql-connector-java-5.1.46/mysql-connector-java-5.1.46-bin.jar /usr/share/java/mysql-connector-java.jar

echo "------------------------------------------------------"
echo "-- Create DBs required by CM"
mysql -u root <<EOF
CREATE DATABASE scm DEFAULT CHARACTER SET utf8 DEFAULT COLLATE utf8_general_ci;
GRANT ALL ON scm.* TO 'scm'@'%' IDENTIFIED BY 'cloudera';

CREATE DATABASE amon DEFAULT CHARACTER SET utf8 DEFAULT COLLATE utf8_general_ci;
GRANT ALL ON amon.* TO 'amon'@'%' IDENTIFIED BY 'cloudera';

CREATE DATABASE rman DEFAULT CHARACTER SET utf8 DEFAULT COLLATE utf8_general_ci;
GRANT ALL ON rman.* TO 'rman'@'%' IDENTIFIED BY 'cloudera';

CREATE DATABASE hue DEFAULT CHARACTER SET utf8 DEFAULT COLLATE utf8_general_ci;
GRANT ALL ON hue.* TO 'hue'@'%' IDENTIFIED BY 'cloudera';

CREATE DATABASE metastore DEFAULT CHARACTER SET utf8 DEFAULT COLLATE utf8_general_ci;
GRANT ALL ON metastore.* TO 'hive'@'%' IDENTIFIED BY 'cloudera';

CREATE DATABASE sentry DEFAULT CHARACTER SET utf8 DEFAULT COLLATE utf8_general_ci;
GRANT ALL ON sentry.* TO 'sentry'@'%' IDENTIFIED BY 'cloudera';

CREATE DATABASE nav DEFAULT CHARACTER SET utf8 DEFAULT COLLATE utf8_general_ci;
GRANT ALL ON nav.* TO 'nav'@'%' IDENTIFIED BY 'cloudera';

CREATE DATABASE navms DEFAULT CHARACTER SET utf8 DEFAULT COLLATE utf8_general_ci;
GRANT ALL ON navms.* TO 'navms'@'%' IDENTIFIED BY 'cloudera';

CREATE DATABASE oozie DEFAULT CHARACTER SET utf8 DEFAULT COLLATE utf8_general_ci;
GRANT ALL ON oozie.* TO 'oozie'@'%' IDENTIFIED BY 'cloudera'
EOF

echo "------------------------------------------------------"
echo "-- Secure MariaDB"
mysql -u root <<EOF
  UPDATE mysql.user SET Password=PASSWORD('cloudera') WHERE User='root';
  DELETE FROM mysql.user WHERE User='';
  DROP DATABASE IF EXISTS test;
  DELETE FROM mysql.db WHERE Db='test' OR Db='test\\_%';
  FLUSH PRIVILEGES;
EOF


echo "------------------------------------------------------"
echo "-- Prepare CM database 'scm'"
/opt/cloudera/cm/schema/scm_prepare_database.sh mysql scm scm cloudera

echo "------------------------------------------------------"
echo "-- Enable passwordless root login via rsa key"
ssh-keygen -f ~/myRSAkey -t rsa -N ""
mkdir /root/.ssh
cat ~/myRSAkey.pub >> ~/.ssh/authorized_keys
chmod 400 ~/.ssh/authorized_keys 
ssh-keyscan -H `hostname` >> ~/.ssh/known_hosts
sed -i 's/#PermitRootLogin yes/PermitRootLogin without-password/' /etc/ssh/sshd_config
systemctl restart sshd

echo "------------------------------------------------------"
echo "-- Start CM, it takes about 2 minutes to be ready"
systemctl start cloudera-scm-server

while [ `curl -s -X GET -u "admin:admin"  http://localhost:7180/api/version` -z ] ;
    do
    echo "waiting 10s for CM to come up.."; 
    sleep 10; 
done


echo "------------------------------------------------------"
echo "-- Now CM is started and the next step is to automate using the CM API"
yum install -y epel-release
yum install -y python-pip
pip install --upgrade pip
pip install cm_client

cat - > pythonCM-API.py <<EOF
import cm_client
from cm_client.rest import ApiException
from collections import namedtuple
from pprint import pprint
import json

cm_client.configuration.username = 'admin'
cm_client.configuration.password = 'admin'
api_url = "http://localhost:7180/api/v30"
api_client = cm_client.ApiClient(api_url)

with open('OneNodeCluster_template.json') as in_file:
    json_str = in_file.read()

Response = namedtuple("Response", "data")
dst_cluster_template=api_client.deserialize(response=Response(json_str),response_type=cm_client.ApiClusterTemplate)
cm_api_instance = cm_client.ClouderaManagerResourceApi(api_client)
command = cm_api_instance.import_cluster_template(body=dst_cluster_template)
EOF

sed -i "s/YourHostName/`hostname`/g" OneNodeCluster_template.json
python pythonCM-API.py

echo "-- At this point you can login into Cloudera Manager host on port 7180 and follow the deployment of the cluster"


