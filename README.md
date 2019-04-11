# One Node CDH Cluster

This script automatically sets up a CDH cluster on a single VM with the following 10 services: Kafka, Kudu, Impala, Hue, Hive, Spark, Oozie, HDFS, YARN and ZK. More services can be added or removed by updating the template used.

As this cluster is meant to be used for demos, experimenting, training, and workshops, it doesn't setup Kerberos and TLS.

## Instructions

### Provision VM 

- Create a Centos 7 VM with at least 4 vCPUs/16GB RAM.
- If you created the VM on Azure and need to resize the OS disk, you might want to follow these [instructions]

### Configuration and installation

- add inbound rule to the Security Group to allow your IP only, for all ports.
- ssh into VM and copy this repo.

```
$ sudo su -
$ yum install -y git
$ git clone https://github.com/fabiog1901/OneNodeCDHCluster.git
$ chmod +x OneNodeCDHCluster/setup.sh
```

The script `setup.sh` takes the cloud provider name as a parameter: `aws`,`azure`,`gcp`, for example:

```
$ OneNodeCDHCluster/setup.sh aws
```

Wait until the script finishes, check for any error.

### Use

Once the script returns, you can open Cloudera Manager at [http://\<public-IP\>:7180](http://<public-IP>:7180)
