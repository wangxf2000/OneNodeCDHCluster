# IBM Cloud setup notes

Confirm the extra disk is mounted at `/dev/xvdc`

```
$ lsblk
NAME    MAJ:MIN RM  SIZE RO TYPE MOUNTPOINT
xvda    202:0    0  100G  0 disk
├─xvda1 202:1    0    1G  0 part /boot
└─xvda2 202:2    0   99G  0 part /
xvdc    202:32   0  500G  0 disk             <---- HERE!
xvdp    202:240  0   64M  0 disk
```

Now you can start the bootstrap script

```
$ sudo su -
$ yum install -y git
$ git clone https://github.com/fabiog1901/OneNodeCDHCluster.git
$ cd OneNodeCDHCluster
$ chmod +x ibm_setup.sh
$ ./ibm_setup.sh ibm templates/ibm_template.json /dev/xvdc
```

## Notes

If you are running RHEL instead of CentOS, you must run the below to install the EPEL repo:
```
$ rpm -ivh https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm
```


Login into CDSW, go to Admin > Engines and add the following

- to **Environmental variables**:

```
HADOOP_CONF_DIR   /etc/hadoop/conf/
```


