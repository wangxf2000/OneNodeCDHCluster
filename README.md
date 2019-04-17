# One Node CDH Cluster

This script automatically sets up a CDH cluster on the public cloud on a single VM with the following 13 services: NiFi, NiFi CA, NiFi Registry, Kafka, Kudu, Impala, Hue, Hive, Spark, Oozie, HDFS, YARN and ZK. More services can be added or removed by updating the template used.

As this cluster is meant to be used for demos, experimenting, training, and workshops, it doesn't setup Kerberos and TLS.

## Instructions

### Provision VM 

- Create a Centos 7 VM with at least 4 vCPUs/16GB RAM.
- OS disk size: at least 50 GB.
- If you created the VM on Azure and need to resize the OS disk, here are the [instructions](how-to-resize-os-disk.md).

### Configuration and installation

- add inbound rule to the Security Group to allow your IP only, for all ports.
- ssh into VM and copy this repo.

```
$ sudo su -
$ yum install -y git
$ git clone https://github.com/fabiog1901/OneNodeCDHCluster.git
$ cd OneNodeCDHCluster
$ chmod +x setup.sh
```

The script `setup.sh` takes 2 arguments:
- the cloud provider name: `aws`,`azure`,`gcp`.
- the template file, defaults to `default_template.json`

```
$ ./setup.sh aws default_template.json
```
Wait until the script finishes, check for any error.

### Use

Once the script returns, you can open Cloudera Manager at [http://\<public-IP\>:7180](http://<public-IP>:7180)
