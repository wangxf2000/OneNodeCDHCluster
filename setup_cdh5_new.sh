#! /bin/bash
echo "-- Configure and optimize the OS"
echo never > /sys/kernel/mm/transparent_hugepage/defrag
echo never > /sys/kernel/mm/transparent_hugepage/enabled
echo "echo never > /sys/kernel/mm/transparent_hugepage/defrag" >> /etc/rc.d/rc.local
echo "echo never > /sys/kernel/mm/transparent_hugepage/enabled" >> /etc/rc.d/rc.local
# add tuned optimization https://www.cloudera.com/documentation/enterprise/6/6.2/topics/cdh_admin_performance.html
echo  "vm.swappiness = 1" >> /etc/sysctl.conf
sysctl vm.swappiness=1
timedatectl set-timezone UTC
# CDSW requires Centos 7.9, so we trick it to believe it is...
#echo "CentOS Linux release 7.5.1810 (Core)" > /etc/redhat-release

echo "-- Install Java OpenJDK8 and other tools"
yum install -y java-1.8.0-openjdk-devel vim wget curl git bind-utils
yum install -y epel-release
yum install -y python-pip
pip install --upgrade pip==19.3

#echo "-- Installing requirements for Stream Messaging Manager"
#yum install -y gcc-c++ make 
#curl -sL https://rpm.nodesource.com/setup_10.x | sudo -E bash - 
#yum install nodejs -y
#npm install forever -g 

# Check input parameters
case "$1" in
        aws)
            echo "server 169.254.169.123 prefer iburst minpoll 4 maxpoll 4" >> /etc/chrony.conf
            systemctl restart chronyd
            ;;
        azure)
            umount /mnt/resource
            mount /dev/sdb1 /opt
            ;;
        gcp)
            ;;
        *)
            echo $"Usage: $0 {aws|azure|gcp} template-file [docker-device]"
            echo $"example: ./setup.sh azure default_template.json"
            echo $"example: ./setup.sh aws cdsw_template.json /dev/xvdb"
            exit 1
esac

TEMPLATE=$2
# ugly, but for now the docker device has to be put by the user
DOCKERDEVICE=$3


echo "-- Configure networking"
PUBLIC_IP=`curl https://api.ipify.org/`
hostnamectl set-hostname 'cdh02.gyzq.cn'
echo "`hostname -I` `hostname` cdh02" >> /etc/hosts
sed -i "s/HOSTNAME=.*/HOSTNAME=`hostname`/" /etc/sysconfig/network
systemctl disable firewalld
systemctl stop firewalld
setenforce 0
sed -i 's/SELINUX=.*/SELINUX=disabled/' /etc/selinux/config


echo "-- Install CM and MariaDB repo"
# wget http://archive.cloudera.com/cm5/redhat/7/x86_64/cm/cloudera-manager.repo -P /etc/yum.repos.d/
cat - >/etc/yum.repos.d/cm.repo <<EOF
[cm]
name = Cloudera Manager
baseurl = http://192.168.0.2/cm5.16.2/
gpgcheck=0
EOF

cat - >/etc/yum.repos.d/mysql.repo <<EOF
[cm]
name = Mysql
baseurl = http://192.168.0.2/mysql/
gpgcheck=0
EOF

yum clean all
rm -rf /var/cache/yum/
yum repolist

yum install -y cloudera-manager-daemons cloudera-manager-agent cloudera-manager-server
#yum install -y MariaDB-server MariaDB-client
yum install -y mysql-community-client
cat conf/mariadb.config > /etc/my.cnf


echo "--Enable and start MariaDB"
systemctl enable mariadb
systemctl start mariadb

echo "-- Install JDBC connector"
wget https://dev.mysql.com/get/Downloads/Connector-J/mysql-connector-java-5.1.46.tar.gz -P ~
tar zxf ~/mysql-connector-java-5.1.46.tar.gz -C ~
mkdir -p /usr/share/java/
cp ~/mysql-connector-java-5.1.46/mysql-connector-java-5.1.46-bin.jar /usr/share/java/mysql-connector-java.jar
rm -rf ~/mysql-connector-java-5.1.46*

echo "-- Create DBs required by CM"
mysql -u root  -h 192.168.0.2 < ~/OneNodeCDHCluster/scripts/create_db.sql

#echo "-- Secure MariaDB"
#mysql -u root  < ~/OneNodeCDHCluster/scripts/secure_mariadb.sql

echo "-- Prepare CM database 'scm'"
/usr/share/cmf/schema/scm_prepare_database.sh mysql scm scm "Gyzq\!123"  -h 192.168.0.2 
#/opt/cloudera/cm/schema/scm_prepare_database.sh mysql scm scm cloudera


echo "-- Enable passwordless root login via rsa key"
ssh-keygen -f ~/myRSAkey -t rsa -N ""
mkdir ~/.ssh
cat ~/myRSAkey.pub >> ~/.ssh/authorized_keys
chmod 400 ~/.ssh/authorized_keys
ssh-keyscan -H `hostname` >> ~/.ssh/known_hosts
#sed -i 's/.*PermitRootLogin.*/PermitRootLogin without-password/' /etc/ssh/sshd_config

#systemctl restart sshd

echo "-- Start CM, it takes about 2 minutes to be ready"
systemctl start cloudera-scm-server

while [ `curl -s -X GET -u "admin:admin"  http://localhost:7180/api/version` -z ] ;
    do
    echo "waiting 10s for CM to come up..";
    sleep 10;
done

echo "-- Now CM is started and the next step is to automate using the CM API"


pip install cm_client
#pip install paho-mqtt 

yum -y install krb5-server krb5-libs krb5-auth-dialog krb5-workstation openldap-clients


#sed -i "s/YourHostname/`hostname -f`/g" ~/OneNodeCDHCluster/$TEMPLATE
#sed -i "s/YourCDSWDomain/cdsw.`hostname -i`.nip.io/g" ~/OneNodeCDHCluster/$TEMPLATE
#sed -i "s/YourPrivateIP/`hostname -I | tr -d '[:space:]'`/g" ~/OneNodeCDHCluster/$TEMPLATE
#sed -i "s#YourDockerDevice#$DOCKERDEVICE#g" ~/OneNodeCDHCluster/$TEMPLATE

#sed -i "s/YourHostname/`hostname -f`/g" ~/OneNodeCDHCluster/scripts/create_cluster.py

#python ~/OneNodeCDHCluster/scripts/create_cluster.py $TEMPLATE


echo "-- At this point you can login into Cloudera Manager host on port 7180 and follow the deployment of the cluster"

#echo "--Now start efm and minifi"
# configure and start EFM and Minifi
#systemctl enable efm
#systemctl start efm
#systemctl enable minifi
#systemctl start minifi
