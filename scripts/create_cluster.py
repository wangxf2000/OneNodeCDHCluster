from __future__ import print_function
import cm_client
from cm_client.rest import ApiException
from collections import namedtuple
from pprint import pprint
import json
import time
import sys

def wait(cmd, timeout=None):
    SYNCHRONOUS_COMMAND_ID = -1
    if cmd.id == SYNCHRONOUS_COMMAND_ID:
        return cmd

    SLEEP_SECS = 5
    if timeout is None:
        deadline = None
    else:
        deadline = time.time() + timeout

    try:
        cmd_api_instance = cm_client.CommandsResourceApi(api_client)
        while True:
            cmd = cmd_api_instance.read_command(long(cmd.id))
            pprint(cmd)
            if not cmd.active:
                return cmd

            if deadline is not None:
                now = time.time()
                if deadline < now:
                    return cmd
                else:
                    time.sleep(min(SLEEP_SECS, deadline - now))
            else:
                time.sleep(SLEEP_SECS)
    except ApiException as e:
        print("Exception when calling ClouderaManagerResourceApi->import_cluster_template: %s\n" % e)


cm_client.configuration.username = 'admin'
cm_client.configuration.password = 'admin'
api_client = cm_client.ApiClient("http://localhost:7180/api/v32")

cm_api = cm_client.ClouderaManagerResourceApi(api_client)

# accept trial licence
cm_api.begin_trial()

# Install CM Agent on host
with open ("/root/myRSAkey", "r") as f:
    key = f.read()


instargs = cm_client.ApiHostInstallArguments(host_names=['YourHostname'], 
                                             user_name='root', 
                                             private_key=key, 
                                             cm_repo_url='http://archive.cloudera.com/cm5/', 
                                             java_install_strategy='NONE', 
                                             ssh_port=22, 
                                             passphrase='')

cmd = cm_api.host_install_command(body=instargs)
wait(cmd)




# Configure Hosts with property needed by SMM
host_api = cm_client.AllHostsResourceApi(api_client)

message = 'updating CM Agent safety valve for SMM'
body = cm_client.ApiConfigList() # ApiConfigList | Configuration changes. (optional)
body.items = [cm_client.ApiConfig(name="host_agent_safety_valve", value="kafka_broker_topic_partition_metrics_for_smm_enabled=true")]

cmd = host_api.update_config(message=message, body=body)
print("host_api.update_config finished")

    
    
    
# create MGMT/CMS
mgmt_api = cm_client.MgmtServiceResourceApi(api_client)
api_service = cm_client.ApiService()

api_service.roles = [cm_client.ApiRole(type='SERVICEMONITOR'), 
    cm_client.ApiRole(type='HOSTMONITOR'), 
    cm_client.ApiRole(type='EVENTSERVER'),  
    cm_client.ApiRole(type='ALERTPUBLISHER')]

mgmt_api.auto_assign_roles() # needed?
mgmt_api.auto_configure()    # needed?
mgmt_api.setup_cms(body=api_service)
cmd = mgmt_api.start_command()
wait(cmd)
print("mgmt_api start ok!")
print(cmd)

# create the cluster using the template
with open(sys.argv[1]) as f:
    json_str = f.read()

Response = namedtuple("Response", "data")
dst_cluster_template=api_client.deserialize(response=Response(json_str),response_type=cm_client.ApiClusterTemplate)
print("dst_cluster_template:")
print(dst_cluster_template)
cmd = cm_api.import_cluster_template(add_repositories=True, body=dst_cluster_template)
print("import_cluster_template")
wait(cmd)

# API Docs for reference
# https://archive.cloudera.com/cm6/6.2.0/generic/jar/cm_api/swagger-html-sdk-docs/python/docs/ClouderaManagerResourceApi.html
# https://archive.cloudera.com/cm6/6.2.0/generic/jar/cm_api/swagger-html-sdk-docs/python/docs/MgmtServiceResourceApi.html
