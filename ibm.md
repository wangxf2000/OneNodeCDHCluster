# IBM Cloud setup notes

Login into CDSW, go to Admin > Engines and add the following

- to **Environmental variables**:

```
HADOOP_CONF_DIR   /etc/hadoop/conf2/
SPARK_CONF_DIR    /etc/spark/conf2/
```

- to **Mounts**, with *Write Access* checked:

```
/etc/hadoop/conf2
/etc/spark/conf2
```
