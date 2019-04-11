if [ -z $1 ]
then
    echo "must add parameter ['aws' | 'azure' | 'gcp']"
    echo "example: ./setup.sh aws"
    exit 1
fi

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

if [ $1 = "azure" ]
then
    echo "It's azure!"
    curl -sSL https://raw.githubusercontent.com/cloudera/director-scripts/master/azure-bootstrap-scripts/os-generic-bootstrap.sh | sh
    sleep 10
fi

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
cat mariadb.config > /etc/my.cnf 

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
mysql -u root < create_db.sql

echo "------------------------------------------------------"
echo "-- Secure MariaDB"
mysql -u root < secure_mariadb.sql

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
sed -i 's/.*PermitRootLogin.*/PermitRootLogin without-password/' /etc/ssh/sshd_config
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

sed -i "s/YourHostName/`hostname`/g" OneNodeCluster_template.json
sed -i "s/YourHostName/`hostname`/g" create_cluster.py
python create_cluster.py

echo "-- At this point you can login into Cloudera Manager host on port 7180 and follow the deployment of the cluster"


