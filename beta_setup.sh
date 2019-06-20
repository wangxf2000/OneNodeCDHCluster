



# CSD for C5
wget https://archive.cloudera.com/cdsw1/1.5.0/csd/CLOUDERA_DATA_SCIENCE_WORKBENCH-CDH5-1.5.0.jar -P /opt/cloudera/csd/
wget https://archive.cloudera.com/spark2/csd/SPARK2_ON_YARN-2.4.0.cloudera1.jar -P /opt/cloudera/csd/
chown cloudera-scm:cloudera-scm /opt/cloudera/csd/*
chmod 644 /opt/cloudera/csd/*
